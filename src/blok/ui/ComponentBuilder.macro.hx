package blok.ui;

import blok.macro.ClassBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using blok.macro.FieldBuilder;
using blok.macro.MacroTools;

function build() {
  var builder = ClassBuilder.fromContext();
  var options:FieldBuilderOptions = { serialize: false };
  var cls = Context.getLocalClass().get();
  var hasChildren = false;
  var fieldBuilders:Array<FieldBuilder> = [
    builder.parseAttributeFields(options),
    builder.parseSignalFields(options),
    builder.parseObservableFields(options)
  ].flatten();

  builder.parseActionFields();
  builder.findFieldsByMeta(':resource').map(f -> createResource(builder, f));
  
  var inits:Array<Expr> = fieldBuilders
    .filter(f -> f.lateInit != true)
    .map(p -> p.init);
  var computed:Array<Expr> = fieldBuilders
    .filter(f -> f.lateInit == true)
    .map(f -> f.init)
    .concat(builder.parseComputedFields());
  var updates = fieldBuilders.map(p -> p.update);
  var props = fieldBuilders.map(p -> p.prop);
  
  for (field in builder.findFieldsByMeta(':children')) {
    if (hasChildren) {
      Context.error('Only one :children field is allowed per component', field.pos);
    }
    hasChildren = true;

    var prop = props.find(f -> f.name == field.name);
    if (prop == null) {
      Context.error('Invalid target for :children. Must be a :attribute, :signal or :observable field', field.pos);
    }
    prop.meta.push({ name: ':children', params: [], pos: prop.pos });
  }

  var propType:ComplexType = TAnonymous(props);
  var computation:Expr = if (computed.length > 0) macro {
    var prevOwner = blok.signal.Graph.setCurrentOwner(Some(this));
    try $b{computed} catch (e) {
      blok.signal.Graph.setCurrentOwner(prevOwner);
      throw e;
    }
    blok.signal.Graph.setCurrentOwner(prevOwner);
  } else macro null;

  switch builder.findField('setup') {
    case Some(_):
    case None: builder.add(macro class {
      function setup() {}
    });
  }

  switch builder.findField('new') {
    case Some(field): switch field.kind {
      case FFun(f):
        if (f.args.length > 0) {
          Context.error(
            'You cannot pass arguments to this constructor -- it can only '
            + 'be used to run code at initialization.',
            field.pos
          );
        }
        
        if (field.access.contains(APublic)) {
          Context.error(
            'Component constructors must be private (remove the `public` keyword)',
            field.pos
          );
        }

        f.args = [ { name: 'node' } ];
        var expr = f.expr;
        f.expr = macro {
          __node = node;
          var props:$propType = __node.getProps();
          @:mergeBlock $b{inits};
          $computation;
          blok.signal.Observer.untrack(() -> $expr);
        }
      default: 
        throw 'assert';
    }
    case None:
      builder.add(macro class {
        private function new(node) {
          __node = node;
          var props:$propType = __node.getProps();
          @:mergeBlock $b{inits};
          ${computation};
        }
      });
  }
  
  var createParams = cls.params.toTypeParamDecl();
  var markupType = TAnonymous(props.concat((macro class {
    @:optional public final key:blok.diffing.Key;
  }).fields));
  var constructors = macro class {
    public static function node(props:$propType, ?key:Null<blok.diffing.Key>):blok.ui.VNode {
      return new blok.ui.VComponent(componentType, props, $i{cls.name}.new, key);
    }

    public inline static function fromMarkup(props:$markupType):blok.ui.VNode {
      return node(props, props.key);
    }
  };

  builder.addField(constructors
    .getField('node')
    .unwrap()
    .applyParameters(createParams));
  builder.addField(constructors
    .getField('fromMarkup')
    .unwrap()
    .withPos(cls.pos)
    .applyParameters(createParams));

  builder.add(macro class {
    public static final componentType = new kit.UniqueId();

    function __updateProps() {
      blok.signal.Action.run(() -> {
        var props:$propType = __node.getProps();
        @:mergeBlock $b{updates};
      });
    }
    
    public function canBeUpdatedByNode(node:blok.ui.VNode):Bool {
      return node.type == componentType;
    }
  });

  return builder.export();
}

private function createResource(builder:ClassBuilder, field:Field) {
  switch field.kind {
    case FVar(t, e):
      if (t == null) Context.error(':resource fields cannot infer return types', field.pos);
      if (e == null) Context.error(':resource fields require an expression', field.pos);
      if (!field.access.contains(AFinal)) Context.error(':resource fields must be final', field.pos);

      var name = field.name;
      var getterName = 'get_$name';
      var backingName = '__backing_$name';
      var createName = '__create_$name';

      field.name = createName;
      field.meta.push({ name: ':noCompletion', params: [], pos: (macro null).pos });
      field.kind = FFun({
        args: [],
        ret: macro:blok.suspense.Resource<$t>,
        expr: macro return new blok.suspense.Resource<$t>(() -> $e)
      });

      builder.addField({
        name: name,
        access: field.access,
        kind: FProp('get', 'never', macro:blok.suspense.Resource<$t>),
        pos: (macro null).pos
      });

      builder.add(macro class {
        var $backingName:Null<blok.suspense.Resource<$t>> = null;

        function $getterName():blok.suspense.Resource<$t> {
          if (this.$backingName == null) {
            this.$backingName = this.$createName(); 
          }
          return this.$backingName;
        }
      });
    default:
      Context.error(':resource fields cannot be methods', field.pos);
  }
}
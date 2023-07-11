package blok.ui;

import haxe.macro.Expr;
import haxe.macro.Context;
import blok.macro.ClassBuilder;

using blok.macro.MacroTools;

function build() {
  var builder = ClassBuilder.fromContext();
  var cls = Context.getLocalClass().get();
  var props:Array<Field> = [];
  var inits:Array<Expr> = [];
  var updates:Array<Expr> = [];
  
  failOnInvalidMeta(builder, ':signal');
  failOnInvalidMeta(builder, ':action');
  failOnInvalidMeta(builder, ':computed');
  failOnInvalidMeta(builder, ':observable');

  for (field in builder.findFieldsByMeta(':constant')) {
    switch field.kind {
      case FVar(t, e):
        if (!field.access.contains(AFinal)) {
          Context.error('@:constant fields must be final', field.pos);
        }
  
        var name = field.name;
        var backingName = '__backing_$name';
        var getterName = 'get_$name';

        field.kind = FProp('get', 'never', t);

        builder.add(macro class {
          @:noCompletion var $backingName:$t;

          @:noCompletion inline function $getterName() return this.$backingName;
        });

        inits.push(if (e == null) {
          macro this.$backingName = props.$name;
        } else {
          macro this.$backingName = props.$name ?? $e;
        });
        updates.push(macro if (this.$backingName != props.$name) {
          changed++;
          this.$backingName = props.$name;
        });
        props.push(createProp(name, t, e != null, field.pos));
      default:
        Context.error('Invalid field', field.pos);
    }
  }

  var propType:ComplexType = TAnonymous(props);

  switch builder.findField('setup') {
    case Some(_):
    case None: builder.add(macro class {
      function setup() {}
    });
  }

  switch builder.findField('new') {
    case Some(field):
      Context.error('Custom constructors are not ready yet', field.pos);
    case None:
      builder.add(macro class {
        private function new(node) {
          __node = node;
          var props:$propType = __node.getProps();
          @:mergeBlock $b{inits};
        }
      });
  }

  var createParams = cls.params.length > 0
    ? [ for (p in cls.params) { name: p.name, constraints: p.extractTypeParams() } ]
    : [];

  builder.addField({
    name: 'node',
    access: [ AStatic, APublic ],
    pos: (macro null).pos,
    meta: [],
    kind: FFun({
      params: createParams,
      args: [
        { name: 'props', type: macro:$propType },
        { name: 'key', type: macro:Null<blok.diffing.Key>, opt: true }
      ],
      expr: macro return new blok.ui.VComponent(componentType, props, $i{cls.name}.new, key),
      ret: macro:blok.ui.VNode
    })
  });

  builder.add(macro class {
    public static final componentType = new kit.UniqueId();

    function __updateProps():Bool {
      var changed:Int = 0;
      var props:$propType = __node.getProps();
      @:mergeBlock $b{updates};
      return changed > 0;
    }
    
    public function canBeUpdatedByNode(node:VNode):Bool {
      return node.type == componentType;
    }
  });

  return builder.export();
}

private function failOnInvalidMeta(builder:ClassBuilder, meta:String) {
  for (field in builder.findFieldsByMeta(meta)) {
    Context.error('$meta fields are not allowed on StaticComponents. '
      + 'Did you mean to use an ObserverComponent?', field.pos);
  }
}

private function createProp(name:String, type:ComplexType, isOptional:Bool, pos:Position):Field {
  return {
    name: name,
    pos: pos,
    meta: isOptional ? [{name: ':optional', pos: pos}] : [],
    kind: FVar(type, null)
  }
}

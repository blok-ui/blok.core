package blok.ui;

import blok.macro.ClassBuilder;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using blok.macro.MacroTools;
using haxe.macro.Tools;

// @todo: Refactor this, try to create something that is easier
// to share across our various reactive objects. Ideally we'll
// merge it with ReactiveObjectBuilder?
function build():Array<Field> {
  var builder = ClassBuilder.fromContext();
  var cls = Context.getLocalClass().get();
  var fieldBuilders:Array<ComponentFieldBuilder> = [];

  for (field in builder.findFieldsByMeta(':constant')) {
    fieldBuilders.push(createConstantField(builder, field));
  }
  
  for (field in builder.findFieldsByMeta(':signal')) {
    fieldBuilders.push(createSignalField(builder, field, false));
  }

  for (field in builder.findFieldsByMeta(':action')) switch field.kind {
    case FFun(f):
      if (f.ret != null && f.ret != macro:Void) {
        Context.error(':action methods cannot return anything', field.pos);
      }
      var expr = f.expr;
      f.expr = macro blok.signal.Action.run(() -> $expr);
    default:
      Context.error(':action fields must be functions', field.pos);
  }

  for (field in builder.findFieldsByMeta(':resource')) {
    createResource(builder, field);
  }

  var computed:Array<Expr> = [];
  var inits = fieldBuilders.map(p -> p.init);
  
  for (field in builder.findFieldsByMeta(':observable')) {
    var f = createSignalField(builder, field, true);
    fieldBuilders.push(f);
    computed.push(f.init);
  }

  var updates = fieldBuilders.map(p -> p.update);
  var props = fieldBuilders.map(p -> p.prop);
  var propType:ComplexType = TAnonymous(props);
  
  for (field in builder.findFieldsByMeta(':computed')) {
    computed.push(createComputed(builder, field));
  }

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
  
  var createParams = cls.params.length > 0
    ? [ for (p in cls.params) { name: p.name, constraints: p.extractTypeParams() } ]
    : [];

  builder.addField({
    name: 'node',
    access: [ AStatic, APublic ],
    pos: cls.pos,
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

private typedef ComponentFieldBuilder = {
  public final name:String;
  public final init:Expr;
  public final update:Expr;
  public final prop:Field;
}

private function createConstantField(builder:ClassBuilder, field:Field):ComponentFieldBuilder {
  return switch field.kind {
    case FVar(t, e) if (t == null):
      Context.error('Expected a type', field.pos);
    case FVar(t, e):
      var name = field.name;
      var backingName = '__backing_$name';
      var getterName = 'get_$name';

      if (!field.access.contains(AFinal)) {
        if (Compiler.getConfiguration().debug) {
          Context.error(
            '@:constant fields must be final.',
            field.pos
          );
        }
      }
      
      field.kind = FProp('get', 'never', t);
      
      var expr = switch e {
        case macro null: macro new blok.signal.Signal(null);
        default: e;
      };

      builder.add(macro class {
        @:noCompletion final $backingName:blok.signal.Signal<$t>;

        function $getterName():$t {
          return this.$backingName.get();
        }
      });

      return {
        name: name,
        init: if (e == null) {
          macro this.$backingName = props.$name;
        } else {
          macro @:pos(e.pos) this.$backingName = props.$name ?? $e;
        },
        update: if (e == null) { 
          macro this.$backingName.set(props.$name);
        } else {
          macro @:pos(e.pos) this.$backingName.set(props.$name ?? $e);
        },
        prop: createProp(field.name, t, e != null, Context.currentPos())
      };
    default:
      Context.error('Invalid field', field.pos);
  }

}

private function createSignalField(builder:ClassBuilder, field:Field, isReadonly:Bool):ComponentFieldBuilder {
  var name = field.name;
  if (!field.access.contains(AFinal)) {
    if (Compiler.getConfiguration().debug) {
      Context.warning(
        '@:signal and @:observable fields are strongly encouraged to be final. They will be converted to final fields by the compiler for you, which may be confusing.',
        field.pos
      );
    }
    field.access.push(AFinal);
  }

  return switch field.kind {
    case FVar(t, e) if (t == null):
      Context.error('Expected a type', field.pos);
    case FVar(t, e) if (!isReadonly):
      var type = switch t {
        case macro:Null<$t>: macro:blok.signal.Signal<Null<$t>>;
        default: macro:blok.signal.Signal<$t>;
      }
      var isOptional = e != null;
      
      field.kind = FVar(type, switch e {
        case macro null: macro new blok.signal.Signal(null);
        default: e;
      });

      {
        name: name,
        init: createInit(field.name, e),
        update: if (isOptional) {
          macro if (props.$name != null) this.$name.set(props.$name);
        } else {
          macro this.$name.set(props.$name);
        },
        prop: createProp(field.name, t, e != null, Context.currentPos())
      };
    case FVar(t, e) if (isReadonly):
      var backingName = '__backing_$name';
      var type = switch t {
        case macro:Null<$t>: macro:blok.signal.Signal.ReadonlySignal<Null<$t>>;
        default: macro:blok.signal.Signal.ReadonlySignal<$t>;
      }
      var isOptional = e != null;
      var expr = switch e {
        case null: macro null; // Won't actually be used.
        case macro null: macro new blok.signal.Signal.ReadonlySignal(null);
        default: macro cast ($e:blok.signal.Signal.ReadonlySignal<$t>);
      };

      builder.add(macro class {
        @:noCompletion final $backingName:blok.signal.Signal<$type>;
      });

      field.kind = FVar(type, null);

      var init:Array<Expr> = [
        if (e == null) {
          macro this.$backingName = props.$name;
        } else {
          macro this.$backingName = props.$name ?? $expr;
        },
        switch t {
          case macro:Null<$_>:
            macro this.$name = new blok.signal.Computation(() -> this.$backingName.get()?.get());
          default:
            macro this.$name = new blok.signal.Computation(() -> this.$backingName.get().get());
        }
      ];

      {
        name: name,
        init: macro @:mergeBlock $b{init},
        update: if (isOptional) {
          macro if (props.$name != null) this.$backingName.set(props.$name);
        } else {
          macro this.$backingName.set(props.$name);
        },
        prop: createProp(field.name, type, e != null, Context.currentPos())
      }
    default:
      Context.error('Invalid field', field.pos);
  }
}

private function createComputed(builder:ClassBuilder, field:Field):Expr {
  return switch field.kind {
    case FVar(t, e):
      if (t == null) {
        Context.error('@:computed field require an explicit type', field.pos);
      }
      if (e == null) {
        Context.error('@:computed fields require an expression', field.pos);
      }
      if (!field.access.contains(AFinal)) {
        Context.error('@:computed fields must be final', field.pos);
      }

      var name = field.name;
      var getterName = 'get_$name';
      var backingName = '__backing_$name';
      var createName = '__create_$name';

      field.name = createName;
      field.meta.push({ name: ':noCompletion', params: [], pos: (macro null).pos });
      field.kind = FFun({
        args: [],
        ret: macro:blok.signal.Computation<$t>,
        expr: macro return new blok.signal.Computation<$t>(() -> $e)
      });

      builder.addField({
        name: name,
        access: field.access,
        kind: FProp('get', 'never', macro:blok.signal.Computation<$t>),
        pos: (macro null).pos
      });

      builder.add(macro class {
        var $backingName:Null<blok.signal.Computation<$t>> = null;

        @:noCompletion
        inline function $getterName():blok.signal.Computation<$t> {
          blok.debug.Debug.assert(this.$backingName != null);
          return this.$backingName;
        }
      });

      return macro this.$backingName = this.$createName();
    default:
      Context.error('Invalid field', field.pos);
  }
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

private function createInit(name:String, e:Null<Expr>) {
  return if (e == null) {
    macro this.$name = props.$name;
  } else {
    macro if (props.$name != null) this.$name = props.$name;
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

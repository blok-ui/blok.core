package blok.macro;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using blok.macro.MacroTools;
using haxe.macro.Tools;

typedef FieldBuilder = {
  public final ?lateInit:Bool;
  public final name:String;
  public final init:Expr;
  public final prop:Field;
  public final update:Null<Expr>;
  public final json:Null<JsonSerializer>;
}

typedef FieldBuilderOptions = {
  public final serialize:Bool;
}

typedef JsonSerializer = {
  public final serializer:Expr;
  public final deserializer:Expr;
}

function parseAttributeFields(builder:ClassBuilder, options:FieldBuilderOptions):Array<FieldBuilder> {
  return builder.findFieldsByMeta(':attribute')
    .map(field -> createAttributeField(builder, field, options));
}

function createAttributeField(builder:ClassBuilder, field:Field, options:FieldBuilderOptions):FieldBuilder {
  return switch field.kind {
    case FVar(t, e) if (t == null):
      Context.error('Expected a type', field.pos);
    case FVar(t, e):
      var name = field.name;
      var backingName = '__backing_$name';
      var getterName = 'get_$name';

      if (!field.access.contains(AFinal)) {
        if (Compiler.getConfiguration().debug) {
          Context.error(':attribute fields must be final.', field.pos);
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
        prop: createProp(field.name, t, e != null, Context.currentPos()),
        json: options.serialize ? createJsonSerializer(field, true, e) : null
      };
    default:
      Context.error('Invalid field for :attribute', field.pos);
  }
}

function parseConstantFields(builder:ClassBuilder, options:FieldBuilderOptions):Array<FieldBuilder> {
  return builder
    .findFieldsByMeta(':constant')
    .map(field -> createConstantField(builder, field, options));
}

function createConstantField(builder:ClassBuilder, field:Field, options:FieldBuilderOptions):FieldBuilder {
  return switch field.kind {
    case FVar(t, e):
      if (!field.access.contains(AFinal)) {
        Context.error('@:constant fields must be final', field.pos);
      }
      
      {
        name: field.name,
        init: createInit(field.name, e),
        update: null,
        prop: createProp(field.name, t, e != null, Context.currentPos()),
        json: options.serialize ? createJsonSerializer(field, true, e) : null
      }
    default:
      Context.error('Invalid field for :constant', field.pos);
  }
}

function parseSignalFields(builder:ClassBuilder, options:FieldBuilderOptions):Array<FieldBuilder> {
  return builder
    .findFieldsByMeta(':signal')
    .map(field -> createSignalField(builder, field, {
      serialize: options.serialize,
      isReadonly: false
    }));
}

function parseObservableFields(builder:ClassBuilder, options:FieldBuilderOptions):Array<FieldBuilder> {
  return builder
    .findFieldsByMeta(':observable')
    .map(field -> createSignalField(builder, field, {
      serialize: options.serialize,
      isReadonly: true
    }));
}

// @todo: This is not useful for Models, as we wrap Observable fields
// in another Signal to allow updates to work correctly. Think on a
// better approach.
function createSignalField(builder:ClassBuilder, field:Field, options:FieldBuilderOptions & { isReadonly:Bool }):FieldBuilder {
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
    case FVar(t, e) if (!options.isReadonly):
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
        lateInit: options.isReadonly,
        init: createInit(field.name, e),
        update: if (isOptional) {
          macro if (props.$name != null) this.$name.set(props.$name);
        } else {
          macro this.$name.set(props.$name);
        },
        prop: createProp(field.name, t, e != null, Context.currentPos()),
        json: options.serialize ? createJsonSerializer(field, false, e) : null
      };
    case FVar(t, e) if (options.isReadonly):
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

      field.kind = FVar(type, null);

      builder.add(macro class {
        @:noCompletion final $backingName:blok.signal.Signal<$type>;
      });

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
        lateInit: options.isReadonly,
        init: macro @:mergeBlock $b{init},
        update: if (isOptional) {
          macro if (props.$name != null) this.$backingName.set(props.$name);
        } else {
          macro this.$backingName.set(props.$name);
        },
        prop: createProp(field.name, type, e != null, Context.currentPos()),
        json: createJsonSerializer(field, false, e)
      }
    default:
      Context.error('Invalid field for a signal', field.pos);
  }
}

function parseComputedFields(builder:ClassBuilder):Array<Expr> {
  return builder.findFieldsByMeta(':computed').map(field -> createComputed(builder, field));
}

function createComputed(builder:ClassBuilder, field:Field):Expr {
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
      Context.error('Invalid field for :computed', field.pos);
  }
}

function parseActionFields(builder:ClassBuilder) {
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
}

function createJsonSerializer(field:Field, isConstant:Bool, ?def:Expr):JsonSerializer {
  return switch field.kind {
    case FVar(t, _) | FProp(_, _, t):
      var meta = field.meta.find(f -> f.name == ':json');
      var name = field.name;
      var access = isConstant ? macro this.$name : macro this.$name.get();
  
      if (meta != null) switch meta.params {
        case [ macro to = ${to}, macro from = ${from} ] | [ macro from = ${from}, macro to = ${to} ]:
          var serializer = macro {
            var value = $access;
            if (value == null) null else $to;
          };
          var deserializer = switch t {
            case macro:Array<$_>:
              macro {
                var value:Array<Dynamic> = Reflect.field(data, $v{name});
                if (value == null) value = [];
                $from;
              };
            default:
              macro {
                var value:Dynamic = Reflect.field(data, $v{name});
                if (value == null) $def else ${from};
              };
          }
          return {
            serializer: serializer,
            deserializer: deserializer
          };
        case []:
          Context.warning('There is no need to mark fields with @:json unless you are defining how they should serialize/unserialize', meta.pos);
        default:
          Context.error('Invalid arguments', meta.pos);
      }
      
      switch t {
        case macro:Dynamic:
          {
            serializer: macro $access,
            deserializer: macro Reflect.field(data, $v{name})
          };
        case macro:Null<$t> if (isModel(t)):
          var path = switch t {
            case TPath(p): p.pack.concat([ p.name ]);
            default: Context.error('Could not resolve type', field.pos);
          }
          {
            serializer: macro $access?.toJson(),
            deserializer: macro {
              var value:Dynamic = Reflect.field(data, $v{name});
              if (value == null) null else  $p{path}.fromJson(value);
            }
          };
        case macro:Array<$t> if (isModel(t)):
          var path = switch t {
            case TPath(p): p.pack.concat([ p.name ]);
            default: Context.error('Could not resolve type', field.pos);
          }
          {
            serializer: macro $access.map(item -> item.toJson()),
            deserializer: macro {
              var values:Array<Dynamic> = Reflect.field(data, $v{name});
              values.map($p{path}.fromJson);
            }
          };
        case t if (isModel(t)):
          var path = switch t {
            case TPath(p): p.pack.concat([ p.name ]);
            default: Context.error('Could not resolve type', field.pos);
          }
          {
            serializer: macro $access?.toJson(),
            deserializer: macro {
              var value:Dynamic = Reflect.field(data, $v{name});
              $p{path}.fromJson(value);
            }
          }
        default:
          {
            serializer: macro $access,
            deserializer: macro Reflect.field(data, $v{name})
          };
      }
    default:
      Context.error('Invalid field for json serialization', field.pos);
  }
}

function isModel(t:ComplexType) {
  return Context.unify(t.toType(), (macro:blok.data.Model).toType());
}

function createInit(name:String, e:Null<Expr>) {
  return if (e == null) {
    macro this.$name = props.$name;
  } else {
    macro if (props.$name != null) this.$name = props.$name;
  }
}

function createProp(name:String, type:ComplexType, isOptional:Bool, pos:Position):Field {
  return {
    name: name,
    pos: pos,
    meta: isOptional ? [{name: ':optional', pos: pos}] : [],
    kind: FVar(type, null)
  }
}

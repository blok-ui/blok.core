package blok.data;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import blok.macro.ClassBuilder;

using Lambda;
using blok.macro.MacroTools;
using haxe.macro.Tools;

// @todo: Try to unify this a bit with our ComponentBuilder. I bet all
// the create functions for `:constant`, `:signal`, etc could be extracted.
function build() {
  var builder = ClassBuilder.fromContext();
  var fieldBuilders:Array<FieldBuilder> = [];

  for (field in builder.findFieldsByMeta(':constant')) {
    fieldBuilders.push(createConstantField(field));
  }
  
  for (field in builder.findFieldsByMeta(':signal')) {
    fieldBuilders.push(createSignalField(field, false));
  }
  
  for (field in builder.findFieldsByMeta(':observable')) {
    fieldBuilders.push(createSignalField(field, true));
  }

  var computed:Array<Expr> = [];
  var inits = fieldBuilders.map(p -> p.init);
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
  
  switch builder.findField('new') {
    case Some(field): switch field.kind {
      case FFun(f):
        if (f.args.length > 0) {
          Context.error(
            'You cannot pass arguments to a Model constructor -- it can only '
            + 'be used to run code at initialization.',
            field.pos
          );
        }
        f.args = [ {
          name: 'props',
          type: propType
        } ];
        var expr = f.expr;
        f.expr = macro {
          @:mergeBlock $b{inits};
          $computation;
          blok.signal.Observer.untrack(() -> $expr);
        }
      default:
        throw 'assert';
    }
    case None:
      builder.add(macro class {
        public function new(props:$propType) {
          @:mergeBlock $b{inits};
          ${computation};
        }
      });
  }

  var cls = Context.getLocalClass().get();
  var pos = cls.pos;
  var clsType = Context.getLocalType().toComplexType();
  var clsTp:TypePath = { pack: cls.pack, name: cls.name };
  var serializers:Array<ObjectField> = fieldBuilders.map(item -> ({
    field: item.name,
    expr: item.json.serializer
  }:ObjectField));
  var deserializers:Array<ObjectField> = fieldBuilders.map(item -> ({
    field: item.name,
    expr: item.json.deserializer
  }:ObjectField));
  var constructors = macro class {
    public static function fromJson(data:{}):$clsType {
      return new $clsTp(${ {
        expr: EObjectDecl(deserializers),
        pos: pos
      } });
    }
  };

  builder.addField(constructors
    .getField('fromJson')
    .unwrap()
    .withPos(pos)
    .applyParameters(cls.params.toTypeParamDecl()));

  builder.add(macro class {
    public function toJson():Dynamic {
      return ${ {
        expr: EObjectDecl(serializers),
        pos: pos
      } };
    }
  });

  return builder.export();
}

typedef FieldBuilder = {
  public final name:String;
  public final init:Expr;
  public final prop:Field;
  public final json:JsonSerializer;
}

typedef JsonSerializer = {
  public final serializer:Expr;
  public final deserializer:Expr;
};

private function createConstantField(field:Field):FieldBuilder {
  return switch field.kind {
    case FVar(t, e):
      if (!field.access.contains(AFinal)) {
        Context.error('@:constant fields must be final', field.pos);
      }

      var json = createJsonSerializer(field, true);
      var name = field.name;

      {
        name: field.name,
        init: createInit(field.name, e),
        prop: createProp(field.name, t, e != null, Context.currentPos()),
        json: json
      }
    default:
      Context.error('Invalid field', field.pos);
  }
}

private function createSignalField(field:Field, isReadonly:Bool):FieldBuilder {
  return switch field.kind {
    case FVar(t, e):
      if (!field.access.contains(AFinal)) {
        if (Compiler.getConfiguration().debug) {
          Context.warning(
            '@:signal and @:observable fields are strongly encouraged to be final. They will be converted to final fields by the compiler for you, which may be confusing.',
            field.pos
          );
        }
        field.access.push(AFinal);
      }
      var json = createJsonSerializer(field, false);
      var type = switch t {
        case macro:Null<$t>: isReadonly 
          ? macro:blok.signal.Signal.ReadonlySignal<Null<$t>>
          : macro:blok.signal.Signal<Null<$t>>;
        default: isReadonly 
          ? macro:blok.signal.Signal.ReadonlySignal<$t>
          : macro:blok.signal.Signal<$t>;
      }
      
      field.kind = FVar(type, switch e {
        case macro null if (isReadonly): macro new blok.signal.Signal(null);
        case macro null: macro new blok.signal.Signal(null);
        default: e;
      });

      var name = field.name;

      {
        name: field.name,
        init: createInit(field.name, e),
        prop: createProp(field.name, isReadonly ? type : t, e != null, Context.currentPos()),
        json: json
      };
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

private function createJsonSerializer(field:Field, isConstant:Bool):JsonSerializer {
  return switch field.kind {
    case FVar(t, e):
      var meta = field.meta.find(f -> f.name == ':json');
      var name = field.name;
      var def = e == null ? macro null : e;
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
      Context.error('Invalid field', field.pos);
  }
}

function extractTypeParams(tp:TypeParameter) {
  return switch tp.t {
    case TInst(kind, _): switch kind.get().kind {
      case KTypeParameter(constraints): constraints.map(t -> t.toComplexType());
      default: [];
    }
    default: [];
  }
}

private function isModel(t:ComplexType) {
  return Context.unify(t.toType(), (macro:blok.data.Model).toType());
}

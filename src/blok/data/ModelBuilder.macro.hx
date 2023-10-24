package blok.data;

import haxe.macro.Compiler;
import blok.macro.ClassBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using blok.macro.FieldBuilder;
using blok.macro.MacroTools;
using haxe.macro.Tools;

function build() {
  var builder = ClassBuilder.fromContext();
  var options:FieldBuilderOptions = { serialize: true };
  var fieldBuilders:Array<FieldBuilder> = [
    builder.parseConstantFields(options),
    builder.findFieldsByMeta(':signal').map(f -> createSimpleSignalField(f, false)),
    builder.findFieldsByMeta(':observable').map(f -> createSimpleSignalField(f, true)),
  ].flatten();

  builder.parseActionFields();

  var inits:Array<Expr> = fieldBuilders
    .filter(f -> f.lateInit != true)
    .map(p -> p.init);
  var computed:Array<Expr> = fieldBuilders
    .filter(f -> f.lateInit == true)
    .map(f -> f.init)
    .concat(builder.parseComputedFields());
  var inits = fieldBuilders.map(p -> p.init);
  var props = fieldBuilders.map(p -> p.prop);
  var propType:ComplexType = TAnonymous(props);
  var computation:Expr = if (computed.length > 0) macro {
    var prevOwner = blok.signal.Graph.setCurrentOwner(Some(this));
    try $b{computed} catch (e) {
      blok.signal.Graph.setCurrentOwner(prevOwner);
      throw e;
    }
    blok.signal.Graph.setCurrentOwner(prevOwner);
  } else macro null;

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

// Using this instead of the default createSignalField as we don't need to
// wrap signals for updates.
private function createSimpleSignalField(field:Field, isReadonly:Bool):FieldBuilder {
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
      var json = field.createJsonSerializer(false);
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
        init: field.name.createInit(e),
        update: null,
        prop: field.name.createProp(isReadonly ? type : t, e != null, Context.currentPos()),
        json: json
      };
    default:
      Context.error('Invalid field', field.pos);
  }
}

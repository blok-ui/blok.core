package blok;

import haxe.macro.Expr;
import haxe.macro.Context;
import blok.tools.BuilderHelpers.*;
import blok.tools.ClassBuilder;

using haxe.macro.Tools;
using blok.tools.BuilderHelpers;

class RecordBuilder {
  public static function build() {
    var builder = ClassBuilder.fromContext();
    var cls = builder.cls;
    var clsTp = builder.getTypePath();
    var props:Array<Field> = [];
    var withProps:Array<Field> = [];
    var withMethods:Array<{ name:String, type:ComplexType }> = [];
    var initializers:Array<Expr> = [];
    var nameBuilder:Array<Expr> = [];
    var withBuilder:Array<ObjectField> = [];
    var fromJson:Array<ObjectField> = [];
    var toJson:Array<ObjectField> = [];

    if (cls.isInterface) return builder.export();

    if (cls.superClass != null) {
      Context.error('Records cannot extend other classes', cls.pos);
    }

    function addProp(name:String, type:ComplexType, isOptional:Bool, isUpdateable:Bool) {
      props.push({
        name: name,
        kind: FVar(type, null),
        access: [ APublic ],
        meta: isOptional ? [ OPTIONAL_META ] : [],
        pos: (macro null).pos
      });
      if (isUpdateable) {
        withProps.push({
          name: name,
          kind: FVar(type, null),
          access: [ APublic ],
          meta: [ OPTIONAL_META ],
          pos: (macro null).pos
        });
        withMethods.push({
          name: name,
          type: type
        });
      }

      // @todo: this could use some cleanup and DRYing. Move some of this
      //        into their own methods?

      var serializeable = Context.getType('blok.JsonSerializable');
      var unserializeable = Context.getType('blok.JsonUnserializable');
      var recordType = Context.getType('blok.Record');

      function checkIfUnserializeable(type, pos) {
        if (!Context.unify(type, unserializeable)) {
          Context.error(
            'This class can be serialized to json but cannot be unserialized.'
            + 'Please ensure it has a `fromJson(data)` static method.', 
            pos
          );
        }
      }

      // This feels a bit hacky :/ 
      function prepareJsonSerializableForHash(t, e:Expr) {
        if (Context.unify(t, recordType)) {
          return macro @:privateAccess {
            var part = $e;
            if (part != null) Std.string(part.hashCode()) else ''; 
          }
        }
        return macro {
          var part = $e;
          if (part != null) haxe.Json.stringify(part.toJson()) else '';
        }
      }

      if (Context.unify(type.toType(), Context.getType('Iterable'))) switch type.toType() {
        case TAbstract(_, [ t ]) | TInst(_, [ t ]) if (Context.unify(t, serializeable)):
          nameBuilder.push(macro $v{name} + ':[' + [ for (c in this.$name) ${prepareJsonSerializableForHash(t, macro c)} ].join(',') + ']');
          toJson.push({
            field: name,
            expr: macro [ for (c in this.$name) c.toJson() ]
          });
          var path = t.getPathExprFromType();
          checkIfUnserializeable(Context.typeof(path), builder.getField(name).pos);
          fromJson.push({
            field: name,
            expr: macro [ for (item in (Reflect.field(data, $v{name}):Array<Dynamic>)) ${path}.fromJson(item) ] 
          });
        default:
          nameBuilder.push(macro $v{name} + ': ' + Std.string(this.$name));
          toJson.push({
            field: name,
            expr: macro this.$name
          });
          fromJson.push({
            field: name,
            expr:  macro Reflect.field(data, $v{name}) 
          });
      } else if (Context.unify(type.toType(), serializeable)) {
        var t = type.toType();
        nameBuilder.push(macro $v{name} + ':' + ${prepareJsonSerializableForHash(t, macro this.$name)});
        toJson.push({
          field: name,
          expr: macro this.$name != null ? this.$name.toJson() : null
        });
        var path = t.getPathExprFromType();
        checkIfUnserializeable(Context.typeof(path), builder.getField(name).pos);
        fromJson.push({
          field: name,
          expr: macro ${path}.fromJson(Reflect.field(data, $v{name})) 
        });
      } else {
        nameBuilder.push(macro $v{name} + ':' + Std.string(this.$name));
        toJson.push({
          field: name,
          expr: 
            if (Context.unify(type.toType(), Context.getType('Date'))) 
              macro this.$name != null ? this.$name.toString() : null
            else
              macro this.$name
        });
        fromJson.push({
          field: name,
          expr:
            if (Context.unify(type.toType(), Context.getType('Date')))
              macro Date.fromString(Reflect.field(data, $v{name}))
            else 
              macro Reflect.field(data, $v{name})
        });
      }
    }

    builder.addFieldMetaHandler({
      name: 'prop',
      hook: Normal,
      options: [],
      build: function (options:{}, builder, field) switch field.kind {
        case FVar(t, e):
          if (t == null) {
            Context.error('Types cannot be inferred for @prop vars', field.pos);
          }

          if (!field.access.contains(APublic)) {
            field.access.remove(APrivate);
            field.access.push(APublic);
          }

          if (!field.access.contains(AFinal)) {
            field.access.push(AFinal);
          }

          var name = field.name;

          addProp(field.name, t, e != null, true);

          initializers.push(e == null
            ? macro this.$name = $i{INCOMING_PROPS}.$name
            : macro this.$name = $i{INCOMING_PROPS}.$name == null ? ${e} : $i{INCOMING_PROPS}.$name 
          );
          withBuilder.push({
            field: name,
            expr: macro $i{INCOMING_PROPS}.$name == null ? this.$name : $i{INCOMING_PROPS}.$name 
          });
        default:  
          Context.error('@prop can only be used on vars', field.pos);
      }
    });

    builder.addFieldMetaHandler({
      name: 'constant',
      hook: Normal,
      options: [],
      build: function (options:{}, builder, field) switch field.kind {
        case FVar(t, e):
          if (t == null) {
            Context.error('Types cannot be inferred for @constant vars', field.pos);
          }

          if (!field.access.contains(APublic)) {
            field.access.remove(APrivate);
            field.access.push(APublic);
          }

          if (!field.access.contains(AFinal)) {
            field.access.push(AFinal);
          }

          var name = field.name;

          addProp(field.name, t, e != null, false);

          initializers.push(e == null
            ? macro this.$name = $i{INCOMING_PROPS}.$name
            : macro this.$name = $i{INCOMING_PROPS}.$name == null ? ${e} : $i{INCOMING_PROPS}.$name 
          );
          withBuilder.push({
            field: name,
            expr: macro this.$name
          });
        default:
          Context.error('@constant can only be used on vars', field.pos);
      }
    });

    builder.addLater(() -> {
      var propType = TAnonymous(props);
      var withPropType = TAnonymous(withProps);
      var clsType = Context.getLocalType().toComplexType();
      var clsTp = builder.getTypePath();

      for (method in withMethods) {
        var name = 'with' + ucFirst(method.name);
        var prop = method.name;
        var type = method.type;
        builder.add(macro class {
          public inline function $name($prop:$type) {
            return with(${{
              expr: EObjectDecl([
                { field: prop, expr: macro $i{prop} }
              ]),
              pos: (macro null).pos
            }});
          }
        });
      }

      return macro class {
        /**
          Construct a record from a dynamic JSON source. This will
          automatically instantiate sub-records and convert some types,
          but will *not* validate the JSON.
        **/
        public static function fromJson(data:Dynamic) {
          return new $clsTp(${ {
            expr: EObjectDecl(fromJson),
            pos: (macro null).pos
          } });
        }

        var __hash:Null<Int> = null;

        public function new($INCOMING_PROPS:$propType) {
          $b{initializers};
        }

        /**
          Create a copy of the current record, changing the given
          properties. If the incoming props are the same as the
          current ones the existing Record will be returned instead
          (this is a bit of a hack to make `a == b` work -- hopefully
          I'll come up with something better).
        **/
        public function with($INCOMING_PROPS:$withPropType) {
          var r = new $clsTp(${ {
            expr: EObjectDecl(withBuilder),
            pos: (macro null).pos
          } });
          if (this.equals(r)) return this;
          return r;
        }

        /**
          Check if all the fields of this Record match the other Record.
        **/
        public function equals(other:$clsType):Bool {
          return hashCode() == other.hashCode();
        }

        public function toJson():Dynamic {
          return ${ {
            expr: EObjectDecl(toJson),
            pos: (macro null).pos
          } };
        }

        public function hashCode():Int {
          if (__hash == null) {
            __hash = blok.tools.ObjectTools.hash($v{cls.pack.concat([ cls.name ]).join('.')} + [ $a{nameBuilder} ].join(''));
          }
          return __hash;
        }
      };
    });

    return builder.export();
  }

  static function ucFirst(str:String) {
    return str.charAt(0).toUpperCase() + str.substr(1);
  }
}
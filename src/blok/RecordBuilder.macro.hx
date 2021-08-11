package blok;

import haxe.macro.Expr;
import haxe.macro.Context;
import blok.tools.BuilderHelpers.*;
import blok.tools.ClassBuilder;

using haxe.macro.Tools;

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
    var toJson:Array<ObjectField> = [];

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
      var recordType = Context.getType('blok.Record');
      
      if (Context.unify(type.toType(), Context.getType('Iterable'))) switch type.toType() {
        case TAbstract(_, [ t ]) if (Context.unify(t, recordType)):
          nameBuilder.push(macro $v{name} + ':[' + [ for (c in this.$name) @:privateAccess c.__stringRepresentation ].join(',') + ']');
          toJson.push({
            field: name,
            expr: macro [ for (c in this.$name) c.toJson() ]
          });
        default:
          nameBuilder.push(macro $v{name} + ': ' + Std.string(this.$name));
          toJson.push({
            field: name,
            expr: macro this.$name
          });
      } else if (Context.unify(type.toType(), recordType)) {
        nameBuilder.push(macro $v{name} + ':' + @:privateAccess this.$name.__stringRepresentation);
        toJson.push({
          field: name,
          expr: macro this.$name.toJson()
        });
      } else {
        nameBuilder.push(macro $v{name} + ':' + Std.string(this.$name));
        toJson.push({
          field: name,
          expr: 
            if (Context.unify(type.toType(), Context.getType('Date'))) 
              macro this.$name.toString()
            else
              macro this.$name
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
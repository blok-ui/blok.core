package blok;

import haxe.macro.Expr;
import haxe.macro.Context;
import blok.core.BuilderHelpers.*;
import blok.core.ClassBuilder;

using haxe.macro.Tools;

class RecordBuilder {
  public static function build() {
    var fields = Context.getBuildFields();
    var cls = Context.getLocalClass().get();
    var clsTp:TypePath = { pack: cls.pack, name: cls.name };
    var builder = new ClassBuilder(cls, fields);
    var props:Array<Field> = [];
    var withProps:Array<Field> = [];
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
      if (isUpdateable) withProps.push({
        name: name,
        kind: FVar(type, null),
        access: [ APublic ],
        meta: [ OPTIONAL_META ],
        pos: (macro null).pos
      });
      var recordType = Context.getType('blok.Record');
      
      if (Context.unify(type.toType(), Context.getType('Iterable'))) switch type.toType() {
        case TAbstract(_, [ t ]) if (Context.unify(t, recordType)):
          nameBuilder.push(macro $v{name} + ': [' + [ for (c in this.$name) @:privateAccess c.__stringRepresentation ].join(',') + ']');
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
        nameBuilder.push(macro $v{name} + ': ' + @:privateAccess this.$name.__stringRepresentation);
        toJson.push({
          field: name,
          expr: macro this.$name.toJson()
        });
      } else {
        nameBuilder.push(macro $v{name} + ': ' + Std.string(this.$name));
        toJson.push({
          field: name,
          expr: macro this.$name
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
      return macro class {
        final __stringRepresentation:String;

        public function new($INCOMING_PROPS:$propType) {
          $b{initializers};
          __stringRepresentation = $v{cls.pack.concat([ cls.name ]).join('.')} + ' { ' + [ $a{nameBuilder} ].join(', ') + ' }';
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
          return __stringRepresentation == other.__stringRepresentation;
        }

        public function toString():String {
          return __stringRepresentation;
        }

        public function toJson():Dynamic {
          return ${ {
            expr: EObjectDecl(toJson),
            pos: (macro null).pos
          } };
        }
      };
    });

    return builder.export();
  }
}
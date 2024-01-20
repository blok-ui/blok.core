package blok.parse;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using Lambda;
using StringTools;
using haxe.macro.Tools;

// @todo: Probably rip off tink_hxx a little less comprehensively here.
class Tag {
  public static final fromMarkupMeta = ':fromMarkup';
  
  public static function fromType(locatedName:Located<String>, type:Type, isBuiltin:Bool = false):Tag {
    var name = locatedName.value;
    var pos = locatedName.pos;
    var reject = createRejector(name, pos);

    return switch type {
      case TLazy(f):
        fromType(locatedName, f(), isBuiltin);
      case TInst(t, _):
        var cls = t.get();
        var statics = cls.statics.get();
        var field = statics.find(f -> f.meta.has(fromMarkupMeta));
        
        if (field == null) {
          reject('it does not have a [$fromMarkupMeta] static method.');
        }

        processType(
          name,
          cls.pack.concat([ cls.name ]).join('.'),
          field.type,
          FromMarkupMethod(field.name),
          isBuiltin,
          pos
        );
      case TType(_.get() => { pack: [], name: t }, []) if (t.startsWith('Class<')):  
        return fromType(locatedName, Context.getType(name), isBuiltin);
      case TFun(_, _):
        processType(name, name, type, FunctionCall, isBuiltin, pos);
      default:
        reject('it is not a valid function');
    }
  }

  public final name:String;
  public final fullName:String;
  public final kind:TagKind;
  public final attributes:TagAttributes;
  public final isBuiltin:Bool;

  public function new(name, fullName, kind, attributes, ?isBuiltin) {
    this.name = name;
    this.fullName = fullName;
    this.kind = kind;
    this.attributes = attributes;
    this.isBuiltin = isBuiltin ?? false;
  }
}

@:structInit
class TagAttributes {
  public final fields:Map<String, ClassField>;
  public final attributesType:Type;
  public final childrenAttribute:TagChildrenAttribute;

  public function getAttribute(name:Located<String>) {
    return fields.get(name.value);
  }

  public function hasAttribute(name:Located<String>) {
    return fields.exists(name.value);
  }
}

enum TagKind {
  FunctionCall;
  FromMarkupMethod(name:String);
}

enum TagChildrenAttribute {
  None;
  Rest;
  Field(name:String, field:ClassField);
}

private function createRejector(name:String, pos:Position) {
  return (reason:String) -> Context.error('$name is not valid markup: $reason', pos);
}

private function processType(name:String, path:String, type:Type, kind:TagKind, isBuiltin:Bool, pos:Position):Tag {
  var reject = createRejector(name, pos);
  return switch type {
    case TLazy(f):
      processType(name, path, f(), kind, isBuiltin, pos);
    case TFun(args, ret):
      args = args.copy();
      switch args[0] {
        case null if (kind.match(FromMarkupMethod(_))):
          reject('its ${Tag.fromMarkupMeta} method has no arguments (expected at least one)');
        case null:
          reject('it has no arguments (expected at least one)');

        case props: switch props.t {
          case TAnonymous(a):
            var obj = a.get();
            var fields:Map<String, ClassField> = [];
            var childrenAttr:TagChildrenAttribute = None;

            for (field in obj.fields) {
              fields.set(field.name, field);
              if (field.meta.has(':children')) switch childrenAttr {
                case None:
                  childrenAttr = Field(field.name, field);
                case Field(name, _):
                  Context.error('Cannot have more than one field acting as children: ${name} already marked', field.pos);
                case Rest:
                  Context.error('Cannot use a children field with a function that takes rest arguments', field.pos);
              }
            }

            switch args[1] {
              case null:
              case arg if (Context.unify(arg.t, (macro:haxe.Rest<Any>).toType())):
                switch childrenAttr {
                  case None:
                    childrenAttr = Rest;
                  default:
                    Context.error('Cannot have both restful children and :children fields', pos);
                }
            }

            return new Tag(name, path, kind, {
              fields: fields,
              attributesType: props.t,
              childrenAttribute: childrenAttr
            }, isBuiltin);
          case _ if (kind.match(FromMarkupMethod(_))):
            reject('its ${Tag.fromMarkupMeta} method must have a first argument that is an anonymous object');
          default:
            reject('it must have a first argument that is an anonymous object');
        }
      }
    case _ if (kind.match(FromMarkupMethod(_))):
      reject('its ${Tag.fromMarkupMeta} field is not a function');
    default:
      reject('it is not a function');
  }
}

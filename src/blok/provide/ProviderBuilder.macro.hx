package blok.provide;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.Tools;

class ProviderBuilder {
  public static function buildGeneric() {
    return switch Context.getLocalType() {
      case TInst(_, [type]):
        buildProvider(type);
      case TInst(_, []):
        buildProvider((macro:Dynamic).toType());
      default:
        throw 'assert';
    }
  }

  public static function createProvider(value:Expr, child:Expr) {
    var type = Context.typeof(value).toComplexType();
    return macro new blok.provide.Provider<$type>($value, $child);
  }

  public static function resolveProvider(el:Expr, kind:Expr) {
    var type = resolveComplexType(kind).toType();
    var tp = switch buildProvider(type) {
      case TPath(p): p;
      default: 
        Context.error('invalid type', kind.pos);
        null;
    }
    return macro $p{tp.pack.concat([ tp.name ])}.from($el);
  }

  static function buildProvider(type:Type) {
    var pack = [ 'blok', 'provide' ];
    var name = 'Provider';
    var ct = type.toComplexType();
    var providerName = name + '_' + type.toString().split('.').join('_');
    var providerPath:TypePath = { pack: pack, name: providerName, params: [] };

    if (!typeExists(pack.concat([ providerName ]).join('.'))) {
      Context.defineType({
        pack: pack,
        name: providerName,
        pos: (macro null).pos,
        kind: TDClass({
          pack: pack,
          name: 'ProviderWidget',
          params: [ TPType(ct) ]
        }, [], false, true, false),
        meta: [],
        fields: (macro class {
          static final type = new blok.core.UniqueId();

          public static function from(el:blok.ui.Element):$ct {
            return switch el.queryAncestor(parent -> parent.getWidget().getWidgetType() == type) {
              case Some(provider):
                (cast provider.getWidget():blok.provide.ProviderWidget<$ct>).value;
              case None:
                // todo: how to handle defaults?
                null;
            }
          }

          public static function of(props:{
            value:$ct,
            child:blok.ui.Widget,
            ?key:blok.ui.Key
          }) {
            return new $providerPath(props.value, props.child, props.key);
          }

          function getWidgetType() {
            return type;
          }
        }).fields
      });
    }

    return TPath(providerPath);
  }

  static function typeExists(name:String) {
    try {
      return Context.getType(name) != null;
    } catch (e:String) {
      return false;
    }
  }

  static function parseAsType(name:String):ComplexType {
    return switch Context.parse('(null:${name})', Context.currentPos()) {
      case macro (null:$type): type;
      default: null;
    }
  }
  
  static function resolveComplexType(expr:Expr):ComplexType {
    return switch expr.expr {
      case ECall(e, params):
        var tParams = params.map(param -> resolveComplexType(param).toString()).join(',');
        parseAsType(resolveComplexType(e).toString() + '<' + tParams + '>');
      default: switch Context.typeof(expr) {
        case TType(_, _):
          parseAsType(expr.toString());
        default:
          Context.error('Invalid expression', expr.pos);
          null;
      }
    }
  }
}
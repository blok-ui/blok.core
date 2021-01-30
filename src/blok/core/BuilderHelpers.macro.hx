package blok.core;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

class BuilderHelpers {
  public static final PROPS = '__props';
  public static final INCOMING_PROPS = '__incomingProps';
  public static final OPTIONAL_META = { name: ':optional', pos: (macro null).pos };

  public static function extractTypeParams(tp:TypeParameter) {
    return switch tp.t {
      case TInst(kind, _): switch kind.get().kind {
        case KTypeParameter(constraints): constraints.map(t -> t.toComplexType());
        default: [];
      }
      default: [];
    }
  }

  public static function extractBuildCt(e:Expr):ComplexType {
    return switch e {
      case macro ($_:$ct): ct;
      default:
        Context.error('Expected a complex type', e.pos);
        null;
    }
  }
}

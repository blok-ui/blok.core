package blok.core;

import haxe.ds.Option;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
using StringTools;

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

  public static function extractComplexTypeFromExpr(e:Expr):ComplexType {
    return switch e {
      case macro ($_:$ct): ct;
      default:
        Context.error('Expected a complex type', e.pos);
        null;
    }
  }

  // Workaround for https://github.com/HaxeFoundation/haxe/issues/9853
  // Stolen from https://github.com/haxetink/tink_macro/blob/6f4e6b9227494caddebda5659e0a36d00da9ca52/src/tink/MacroApi.hx#L70
  static function getCompletion() {
    var sysArgs = Sys.args();
    return switch sysArgs.indexOf('--display') {
      case -1: None;
      case sysArgs[_ + 1] => arg if (arg.startsWith('{"jsonrpc":')):
        var payload:{
          jsonrpc:String,
          method:String,
          params:{
            file:String,
            offset:Int,
            contents:String,
          }
        } = haxe.Json.parse(arg);
        switch payload {
          case { jsonrpc: '2.0', method: 'display/completion' }:
            Some({
              file: payload.params.file,
              content: payload.params.contents,
              pos: payload.params.offset,
            });
          default: None;
        }
      default: None;
    }
  }

  public static function getBuildFieldsSafe():Option<Array<Field>> {
    return switch getCompletion() {
      case Some(v) if (
        v.content != null && (
          v.content.charAt(v.pos - 1) == '@' 
          || (v.content.charAt(v.pos - 1) == ':' 
          && v.content.charAt(v.pos - 2) == '@')
        )
      ):
        None;
      default: 
        Some(Context.getBuildFields());
    }
  }
}

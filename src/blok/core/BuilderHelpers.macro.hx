package blok.core;

import haxe.ds.Option;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import blok.core.ClassBuilder;

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

  public static function createMemoFieldHandler(onInvalidate:(e:Expr)->Void):FieldMetaHandler<{}> {
    return {
      name: 'memo',
      hook: After,
      options: [],
      build: function (_, builder, field) switch field.kind {
        case FFun(f):
          var name = field.name;
          var memoName = '__memo_$name';

          if (f.ret != null && Context.unify(f.ret.toType(), Context.getType('Void'))) {
            Context.error('@memo functions cannot have a Void return type', field.pos);
          }
          if (f.args.length > 0) {
            Context.error('@memo functions cannot have arguments', field.pos);
          }

          builder.add(macro class {
            var $memoName = null;
          });

          f.expr = macro {
            if (this.$memoName != null) return this.$memoName;
            this.$memoName = ${f.expr};
            return this.$memoName;
          };
          
          onInvalidate(macro this.$memoName = null);
        default:
          Context.error('@memo must be used on a method', field.pos);
      }
    };
  }

  // @todo: Extract more shared handlers to here.
}

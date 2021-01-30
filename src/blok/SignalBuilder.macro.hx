package blok;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

// From: https://gist.github.com/nadako/b086569b9fffb759a1b5
class SignalBuilder {
  public static function build() {
    return switch Context.getLocalType() {
      case TInst(_.get() => {name: 'Signal'}, params):
        buildSignal(params);
      default:
        throw 'assert';
    }
  }

  static function buildSignal(params:Array<Type>):ComplexType {
    params = params.filter(p -> p.toString() != 'Void');

    var paramLength = params.length;
    var pack = ['blok'];
    var name = 'Signal${paramLength}';

    if (!typeExists('blok.${name}')) {
      var typeParams:Array<TypeParamDecl> = [];
      var superClassFunctionArgs:Array<ComplexType> = [];
      var dispatchArgs:Array<FunctionArg> = [];
      var listenerCallParams:Array<Expr> = [];

      for (i in 0...paramLength) {
        typeParams.push({name: 'T$i'});
        superClassFunctionArgs.push(TPath({name: 'T$i', pack: []}));
        dispatchArgs.push({name: 'arg$i', type: TPath({name: 'T$i', pack: []})});
        listenerCallParams.push(macro $i{'arg$i'});
      }

      var pos = Context.currentPos();

      Context.defineType({
        pack: pack,
        name: name,
        pos: pos,
        params: typeParams,
        kind: TDClass({
          pack: ['blok'],
          name: "Signal",
          sub: "SignalBase",
          params: [TPType(TFunction(superClassFunctionArgs, macro:Void))]
        }),
        fields: [
          {
            name: "dispatch",
            access: [APublic],
            pos: pos,
            kind: FFun({
              args: dispatchArgs,
              ret: macro:Void,
              expr: macro {
                startDispatch();
                var sub = head;
                while (sub != null) {
                  sub.listener($a{listenerCallParams});
                  if (sub.once) sub.dispose();
                  sub = sub.next;
                }
                endDispatch();
              }
            })
          }
        ]
      });
    }

    return TPath({
      pack: pack,
      name: name,
      params: [for (t in params) TPType(t.toComplexType())]
    });
  }

  static function typeExists(name:String) {
    try {
      return Context.getType(name) != null;
    } catch (e:String) {
      return false;
    }
  }
}


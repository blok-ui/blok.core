package blok.core;

class Debug {
  static public macro function assert(
    expr:haxe.macro.Expr.ExprOf<Bool>,
    ?message:haxe.macro.Expr.ExprOf<String>
  ) {
    switch message {
      case macro null:
        var str = 'Failed assertion: ' + haxe.macro.ExprTools.toString(expr);
        message = macro $v{str};
      default:
    }
    
    if (haxe.macro.Context.defined('debug'))
      return macro @:pos(expr.pos) if (!$expr) throw $message;
    return macro null;
  }
}

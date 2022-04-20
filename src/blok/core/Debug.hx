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
      return macro @:pos(expr.pos) if (!$expr) blok.core.Debug.warn($message);
    return macro null;
  }

  static public macro function warn(expr:haxe.macro.Expr.ExprOf<String>) {
    return macro throw $expr; // @todo: This will allow us to update this later
  }
}

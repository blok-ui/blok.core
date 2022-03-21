package blok.core;

class Debug {
  static public macro function assert(expr:haxe.macro.Expr.ExprOf<Bool>) {
    var str = haxe.macro.ExprTools.toString(expr);
    if (haxe.macro.Context.defined('debug'))
      return macro @:pos(expr.pos) if (!$expr) throw 'Failed assertion: ' + $v{str};
    return macro null;
  }
}

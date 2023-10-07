package blok.parse;

import haxe.macro.Expr;

typedef Located<T> = {
  public final pos:Position;
  public final value:T;
}

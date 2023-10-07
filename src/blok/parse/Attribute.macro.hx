package blok.parse;

import haxe.macro.Expr;

enum AttributeValue {
  ANone;
  AExpr(expr:Expr);
} 

typedef Attribute = {
  public final name:Located<String>;
  public final value:AttributeValue;
}

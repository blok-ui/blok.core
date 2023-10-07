package blok.parse;

import haxe.macro.Expr;

enum NodeDef {
  NText(text:String);
  NNode(tag:NodeTag, attributes:Array<Attribute>, ?children:Array<Node>);
  NFragment(children:Array<Node>);
  NExpr(expr:Expr);
}

enum NodeTag {
  TagBuiltin(name:String);
  TagComponent(path:Array<String>);
  TagAttribute(name:String);
}

typedef Node = {
  public final node:NodeDef;
  public final pos:Position;
}

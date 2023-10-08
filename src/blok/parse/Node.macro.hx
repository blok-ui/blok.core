package blok.parse;

import blok.parse.Located;
import haxe.macro.Expr;

enum NodeDef {
  NText(text:String);
  NNode(name:Located<String>, attributes:Array<Attribute>, ?children:Array<Node>);
  // NNode(tag:NodeTag, attributes:Array<Attribute>, ?children:Array<Node>);
  NFragment(children:Array<Node>);
  NExpr(expr:Expr);
}

// @:using(Node.NodeTagTools)
// enum NodeTag {
//   TagBuiltin(name:Located<String>);
//   TagComponent(path:Array<Located<String>>);
//   TagAttribute(name:Located<String>);
// }

// class NodeTagTools {
//   public static function toString(tag:NodeTag) {
//     return switch tag {
//       case TagBuiltin(name): name.value;
//       case TagComponent(path): path.map(p -> p.value).join('.');
//       case TagAttribute(name): '.' + name.value;
//     }
//   }
// }

typedef Node = {
  public final node:NodeDef;
  public final pos:Position;
}

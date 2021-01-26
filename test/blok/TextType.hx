package blok;

import js.Browser;
import js.html.Node;
import js.html.Text;
import blok.core.Context;

class TextType {
  public static function create(props:{ content:String }, context:Context<Node>):Node {
    return Browser.document.createTextNode(props.content);
  }

  public static function update(node:Node, previousProps:{ content:String }, props:{ content:String }, context:Context<Node>):Node {
    if (previousProps.content != props.content) switch Std.downcast(node, Text) {
      case null:
      case text: 
        text.textContent = props.content;
    }
    return node;
  }
}

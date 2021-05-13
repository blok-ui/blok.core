package blok;

import blok.core.Rendered;

class Text {
  public static function getTextFromRendered(rendered:Rendered) {
    var text:Array<String> = [];
    for (child in rendered.children) switch Std.downcast(child, TextComponent) {
      case null:
        text.push(getTextFromRendered(child.__renderedChildren));
      case comp: 
        text.push(comp.content);
    }
    return text.join(' ');
  }

  public static function fragment(children:Array<VNode>):VNode {
    return VFragment(children);
  }

  public static function text(text:String, ?ref, ?key):VNode {
    return TextComponent.node({ content: text, ref: ref }, key);
  }

  public static function children(children:Array<VNode>, ?ref) {
    return ChildrenComponent.node({ children: children, ref: ref });
  }
}

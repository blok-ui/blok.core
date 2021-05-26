package blok;

import blok.VNode;

class Text {
  public static function getTextFromComponent(comp:Component) {
    var text:Array<String> = [];
    for (child in comp.__children) switch Std.downcast(child, TextComponent) {
      case null:
        text.push(getTextFromComponent(child));
      case comp: 
        text.push(comp.content);
    }
    return text.filter(t -> t.length > 0).join(' ');
  }

  public static function fragment(children:Array<VNode>):VNode {
    return new VFragment(children);
  }

  public static function text(text:String, ?ref, ?key):VNode {
    return TextComponent.node({ content: text, ref: ref }, key);
  }

  public static function children(children:Array<VNode>, ?ref) {
    return ChildrenComponent.node({ children: children, ref: ref });
  }
}

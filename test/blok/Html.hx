package blok;

import js.html.Node;

class Html {
  public static function text(content:String):VNode {
    return VComponent(TextType, { content: content });
  }

  public static function fragment(children:Array<VNode>):VNode {
    return VFragment(children);
  }

  public static function h(tag:String, attrs:{}, children:Array<VNode>, ?ref):VNode {
    return VComponent(NodeType.get(tag), {
      attributes: attrs,
      children: children,
      ref: ref
    });
  }
}

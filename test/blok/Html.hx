package blok;

import blok.core.VNode;

class Html {
  public static function fragment(children:Array<VNode<js.html.Node>>):VNode<js.html.Node> {
    return VFragment(children);
  }

  public static function h(tag:String, props:{
    ?className:String,
    ?id:String,
  }, ?children:Array<VNode<js.html.Node>>, ?ref, ?key):VNode<js.html.Node> {
    return VNative(NodeType.get(tag), props, ref, key, children);
  }

  public static function text(text:String):VNode<js.html.Node> {
    return VNative(TextType, { content: text }, null, null, null);
  }
}

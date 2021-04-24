package blok.dom;

import js.html.Event;

class Html {
  public static function text(content:String):VNode {
    return VComponent(TextType, { content: content });
  }

  public static function div(attrs:{ ?className:String }, children:Array<VNode>):VNode {
    return VComponent(NodeType.get('div'), {
      attributes: attrs,
      children: children
    });
  }

  public static function button(attrs:{
    onclick:(e:Event)->Void
  }, children:Array<VNode>):VNode {
    return VComponent(NodeType.get('button'), {
      attributes: attrs,
      children: children
    });
  }
}

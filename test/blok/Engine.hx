package blok;

import js.html.Node;
import blok.core.RenderResult;
import blok.core.VNode;

using StringTools;

class Engine implements blok.core.Engine<Node> {
  static inline final RENDERED_PROP = '__blok_rendered';

  public function new() {}

  public function traverseSiblings(first:Node):Cursor {
    return new Cursor(first.parentNode, first);
  }

  public function traverseChildren(parent:Node):Cursor {
    return new Cursor(parent, parent.firstChild);
  }

  public function getRendered(node:Node):Null<RenderResult<Node>> {
    return Reflect.field(node, RENDERED_PROP);
  }

  public function setRendered(node:Node, rendered:Null<RenderResult<Node>>):Void {
    Reflect.setField(node, RENDERED_PROP, rendered);
  }

  public function createPlaceholder(component:blok.core.Component<Node>):VNode<Node> {
    return Html.text('');
  }
}

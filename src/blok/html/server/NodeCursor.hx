package blok.html.server;

import blok.adaptor.Cursor;
import blok.debug.Debug;

class NodeCursor implements Cursor {
  var node:Null<Node>;

  public function new(node) {
    this.node = node;
  }

  public function current():Null<Dynamic> {
    return node;
  }

  public function currentChildren():Cursor {
    if (node == null) return new NodeCursor(null);
    return new NodeCursor(node.children[0]);
  }

  public function next() {
    if (node == null) return;

    if (node.parent == null) {
      node = null;
      return;
    }

    assert(node != null);

    var parent = node.parent;
    var index = parent.children.indexOf(node);

    node = parent.children[index + 1];
  }

  public function move(current:Dynamic) {
    node = current;
  }

  public function clone() {
    return new NodeCursor(node);
  }
}

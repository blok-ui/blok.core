package blok.html.server;

import blok.debug.Debug;

/**
  A simple object that can be used as the target for a
  Blok Adaptor, such as for the server-side rendering
  for blok.html or for testing.
**/
abstract class Node {
  public var parent:Null<Node> = null;
  public var children:Array<Node> = [];

  public function prepend(child:Node) {
    assert(child != this);

    if (child.parent != null) child.remove();

    child.parent = this;
    children.unshift(child);
  }

  public function append(child:Node) {
    assert(child != this);

    if (child.parent != null) child.remove();

    child.parent = this;
    children.push(child);
  }

  public function insert(pos:Int, child:Node) {
    assert(child != this);

    if (child.parent != this && child.parent != null) child.remove();

    child.parent = this;

    if (!children.contains(child)) {
      children.insert(pos, child);
      return;
    }

    if (pos >= children.length) {
      pos = children.length;
    }

    var from = children.indexOf(child);

    if (pos == from) return;

    if (from < pos) {
      var i = from;
      while (i < pos) {
        children[i] = children[i + 1];
        i++;
      }
    } else {
      var i = from;
      while (i > pos) {
        children[i] = children[i - 1];
        i--;
      }
    }

    children[pos] = child;
  }

  public function remove() {
    if (parent != null) {
      parent.children.remove(this);
    }
    parent = null;
  }

  abstract public function toString():String;
}

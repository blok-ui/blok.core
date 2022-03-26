package impl;

import blok.core.Debug;

// Note: This `TestingObject` unfortunately introduces a lot of possible
// bugs that can make results confusing. Sometimes the framework is doing
// fine, but this testing implementation is messing things up.
//
// We should consider some way of either making this simpler or by making
// this into the static renderer and then adding tests for it.
class TestingObject {
  public var content:String;
  public var parent:Null<TestingObject> = null;
  public var children:Array<TestingObject> = [];
  
  public function new(content) {
    this.content = content;
  }

  public function append(child:TestingObject) {
    Debug.assert(child is TestingObject);
    Debug.assert(child != this);

    if (child.parent != null) child.remove();

    child.parent = this;
    children.push(child);
  }

  public function insert(pos:Int, child:TestingObject) {
    Debug.assert(child is TestingObject);
    Debug.assert(child != this);

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
  }

  public function toString() {
    return content + children.map(c -> c.toString()).join(' ');
  }
}

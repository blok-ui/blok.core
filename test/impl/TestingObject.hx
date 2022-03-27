package impl;

import blok.render.Object;

class TestingObject extends Object {
  public var content:String;

  public function new(content) {
    this.content = content;
  }
  public function toString() {
    return content + children.map(c -> c.toString()).join(' ');
  }
}

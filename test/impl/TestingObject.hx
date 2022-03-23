package impl;

class TestingObject {
  public var content:String;
  public var parent:Null<TestingObject> = null;
  public var children:Array<TestingObject> = [];
  
  public function new(content) {
    this.content = content;
  }

  public function append(child:TestingObject) {
    child.parent = this;
    children.push(child);
  }

  public function insert(pos:Int, child:TestingObject) {
    child.parent = this;
    if (pos > children.length) 
      children.push(child);
    else 
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

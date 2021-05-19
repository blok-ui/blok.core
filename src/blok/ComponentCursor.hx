package blok;

class ComponentCursor {
  final parent:Component;
  var pos:Int = 0;

  public function new(parent) {
    this.parent = parent;
  }

  public function current() {
    return parent.getComponentAt(pos);
  }

  public function insert(child:Component, ?key) {
    parent.insertComponentAt(pos, child, key);
  }

  public function replace(comp:Component) {
    parent.replaceComponent(current(), comp);
  }

  public function move(comp:Component) {
    parent.moveComponentTo(pos, comp);
  }

  public function delete() {
    return switch current() {
      case null: 
        false;
      case child:
        parent.removeComponent(child);
        step();
        true;
    }
  }

  public function step() {
    pos++;
  }
}

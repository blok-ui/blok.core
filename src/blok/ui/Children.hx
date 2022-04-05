package blok.ui;

abstract Children(Array<Element>) from Array<Element> {
  public inline function new() {
    this = [];
  }

  public inline function add(child:Element) {
    if (this.contains(child)) return;
    this.push(child);
  }

  public inline function rebuild() {
    for (el in this) el.rebuild();
  }
}

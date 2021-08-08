package blok;

@:forward(iterator, remove, insert, concat, indexOf, length, copy)
abstract WidgetList(Array<Widget>) from Array<Widget> {
  public inline function new(?widgets) {
    this = widgets == null ? [] : widgets;
  }

  public inline function add(widget) {
    this.push(widget);
  }

  public inline function set(pos:Int, widget:Widget) {
    this[pos] = widget;
  }

  public inline function has(widget) {
    return this.indexOf(widget) >= 0;
  }

  @:op([])
  public inline function get(pos:Int) {
    return this[pos];
  }

  public inline function find(elt) {
    return Lambda.find(this, elt);
  }
}

package blok.framework;

class Slot {
  public final index:Int;
  public final previous:Null<Element>;

  public function new(index, previous) {
    this.index = index;
    this.previous = previous;
  }
}

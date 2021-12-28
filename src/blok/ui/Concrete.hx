package blok.ui;

/**
  `Concrete` in block refers to whatever the high-level widget tree
  eventually ends up managing. It may be DOM Nodes (in `blok.platform.dom`),
  objects in a game engine (if we ever get around to that), or even 
  nothing at all (in the case of `blok.platform.static`).

  (Is there some irony that the most dynamic thing in Blok is called 
  "Concrete"? Yes. Just roll with it.)

  You'll never have to interact with Concrete directly unless 
  you're building a Blok platform. That's kind of the whole point!
**/
@:forward(map, iterator, length, indexOf)
abstract Concrete(Array<Dynamic>) from Array<Dynamic> {
  public function new(items) {
    this = items;
  }

  public inline function toArray():Array<Dynamic> {
    return this;
  }

  public inline function first() {
    return this[0];
  }

  public inline function last() {
    return this[this.length - 1];
  }
}

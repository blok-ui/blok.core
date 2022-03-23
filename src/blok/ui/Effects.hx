package blok.ui;

typedef Effect = ()->Void;

abstract Effects(Array<Effect>) from Array<Effect> {
  public inline function new() {
    this = [];
  }

  public inline function register(effect:Effect) {
    this.push(effect);
  }

  public inline function dispatch() {
    for (effect in this) effect();
  }
}

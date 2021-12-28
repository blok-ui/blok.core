package blok.ui;

class EffectManager {
  final effects:Array<()->Void> = [];

  public function new() {}

  public function register(effect) {
    effects.push(effect);
  }

  public function dispatch() {
    for (effect in effects) effect();
  }
}

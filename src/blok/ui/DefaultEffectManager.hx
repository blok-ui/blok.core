package blok.ui;

class DefaultEffectManager implements EffectManager {
  final effects:Array<()->Void> = [];

  public function new() {}

  public function register(effect) {
    effects.push(effect);
  }

  public function dispatch() {
    for (effect in effects) effect();
  }
}

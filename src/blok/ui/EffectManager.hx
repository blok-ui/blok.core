package blok.ui;

interface EffectManager {
  public function register(effect:()->Void):Void;
  public function dispatch():Void;
}

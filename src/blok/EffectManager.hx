package blok;

typedef EffectManager = {
  public function register(effect:()->Void):Void;
  public function dispatch():Void;
}

function createEffectManager():EffectManager {
  var effects:Array<()->Void> = [];
  return {
    register: effect -> effects.push(effect),
    dispatch: () -> for (effect in effects) effect()
  };
}

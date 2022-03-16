package blok.ui;

@:allow(blok.ui)
abstract Effect(Array<()->Void>) from Array<()->Void> {
  public inline static function withEffect(child:VNode, effect:()->Void):VNode {
    return EffectUser.node({ child: child, effect: effect });
  }

  public inline static function createTrigger():EffectTrigger {
    return new EffectTrigger(new Effect());
  }

  public inline function new() {
    this = [];
  }

  public inline function register(effect) {
    this.push(effect);
  }

  @:to
  private inline function toArray():Array<()->Void> {
    return this;
  }
}

@:forward(register)
abstract EffectTrigger(Effect) from Effect to Effect {
  public inline function new(effect) {
    this = effect;
  }

  public inline function dispatch() {
    for (effect in this.toArray()) effect();
  }
}

private class EffectUser extends Component {
  @prop var child:VNode = null;
  @prop var effect:()->Void;

  @effect
  function runEffect() {
    effect();
  }

  function render() {
    return child;
  }
}

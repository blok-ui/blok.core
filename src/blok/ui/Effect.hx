package blok.ui;

@:allow(blok.ui)
abstract Effect(Array<()->Void>) from Array<()->Void> {
  public inline static function withEffect(child:VNode, effect:()->Void):VNode {
    return use(effects -> {
      effects.register(effect);
      return child;
    });
  }

  @:noUsing
  public inline static function use(build:(effects:Effect)->VNode) {
    return EffectUser.node({ build: build });
  }

  @:noUsing
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
  @prop var build:(effects:Effect)->VNode;
  var currentEffects:Null<Effect> = null;

  override function __performUpdate(effects:Effect) {
    // @todo: This seems a bit fragile.
    currentEffects = effects;
    super.__performUpdate(effects);
  }

  function render() {
    return build(currentEffects);
  }
}

package blok;

/**
  A simple way to create effects if you, for whatever reason, aren't 
  creating vNodes inside of a Component.
**/
class Effect extends Component {
  public static function withEffect(child:VNode, effect:()->Void):VNode {
    return Effect.node({ child: child, effect: effect });
  }

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

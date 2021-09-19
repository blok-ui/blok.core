package blok;

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

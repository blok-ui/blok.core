package blok.ui;

import blok.signal.Signal;

final class Show extends Component {
  public inline static function when(condition:ReadonlySignal<Bool>, child:()->Child) {
    return node({ condition: condition, child: child });
  }

  public inline static function unless(condition:ReadonlySignal<Bool>, child:()->Child) {
    return node({ condition: condition.map(c -> !c), child: child });
  }

  @:observable final condition:Bool;
  @:constant final child:()->Child;

  function render() {
    return if (condition()) child() else Placeholder.node();
  }
}

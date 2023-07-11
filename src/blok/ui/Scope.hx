package blok.ui;

class Scope extends ObserverComponent {
  public inline static function wrap(child) {
    return node({ child: child });
  }

  @:constant final child:(context:Component)->Child;

  function render():VNode {
    return child(this);
  }
}

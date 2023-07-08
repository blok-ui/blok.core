package blok.ui;

class Scope extends ObserverComponent {
  @:observable final child:Child;

  function render():VNode {
    return child();
  }
}

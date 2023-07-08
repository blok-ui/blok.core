package blok.ui;

class Scope extends AutoComponent {
  @:observable final child:Child;

  public function render():VNode {
    return child();
  }
}

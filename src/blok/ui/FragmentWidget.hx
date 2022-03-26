package blok.ui;

import blok.core.UniqueId;

class FragmentWidget extends Widget {
  static final type = new UniqueId();

  final children:Array<Widget>;

  public function new(children, ?key) {
    super(key);
    this.children = children;
  }

  public inline function getChildren() {
    return children;
  }

  public function getWidgetType():UniqueId {
    return type;
  }

  public function createElement():Element {
    return new FragmentElement(this);
  }
}
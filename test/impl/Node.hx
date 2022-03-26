package impl;

import blok.ui.FragmentWidget;

class Node {
  public inline static function text(text, ?key, ?ref) {
    return new TextWidget(text, key, ref);
  }

  public inline static function wrap(...children) {
    return new WrapperWidget(children.toArray());
  }

  public inline static function fragment(...children) {
    return new FragmentWidget(children.toArray());
  }
}

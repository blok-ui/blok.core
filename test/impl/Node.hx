package impl;

class Node {
  public inline static function text(text, ?key, ?ref) {
    return new TextWidget(text, key, ref);
  }

  public inline static function fragment(...children) {
    return new FragmentWidget(children.toArray());
  }
}

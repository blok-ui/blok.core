package impl;

import blok.ui.Fragment;

class Node {
  public inline static function text(text, ?key, ?ref) {
    return new VText(text, key, ref);
  }

  public inline static function fragment(...children) {
    return Fragment.wrap(...children);
  }
}

package blok.render;

import blok.ui.HydrationCursor;

class ObjectCursor implements HydrationCursor {
  var object:Object;

  public function new(object) {
    this.object = object;
  }

  public function current():Dynamic {
    return object;
  }

  public function currentChildren():HydrationCursor {
    if (object == null) return new ObjectCursor(null);
    return new ObjectCursor(object.children[0]);
  }

  public function next() {
    if (object == null) return;
    if (object.parent == null) {
      object = null;
      return;
    }

    var parent = object.parent;
    var index = parent.children.indexOf(object);

    object = parent.children[index + 1];
  }

  public function move(current:Dynamic) {
    object = current;
  }
}

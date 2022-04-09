package blok.ui;

import blok.core.Debug;

class ObjectWithoutChildrenElement extends ObjectElement {
  public function performBuild(previousWidget:Null<Widget>) {
    if (previousWidget == null) {
      object = createObject();
      platform.insertObject(object, slot, findAncestorObject);
    } else {
      if (previousWidget != widget) updateObject(previousWidget);
    }
  }

  function performHydrate(cursor:HydrationCursor) {
    object = cursor.current();
    Debug.assert(object != null);
    updateObject(object);
    cursor.next();
  }

  override function dispose() {
    if (object != null) platform.removeObject(object, slot);
    super.dispose();
    object = null;
  }

  public function visitChildren(visitor:ElementVisitor) {
    // noop
  }
}

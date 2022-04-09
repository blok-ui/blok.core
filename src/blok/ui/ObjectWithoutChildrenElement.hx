package blok.ui;

import blok.core.Debug;

class ObjectWithoutChildrenElement extends ObjectElement {
  public function performBuild(previousWidget:Null<Widget>) {
    enqueueEffects();
    
    if (previousWidget == null) {
      object = createObject();
      platform.insertObject(object, slot, findAncestorObject);
    } else {
      if (previousWidget != widget) updateObject(previousWidget);
    }
  }

  public function visitChildren(visitor:ElementVisitor) {
    // noop
  }

  function performHydrate(cursor:HydrationCursor) {
    enqueueEffects();

    object = cursor.current();
    Debug.assert(object != null);
    updateObject(object);
    cursor.next();
  }
}

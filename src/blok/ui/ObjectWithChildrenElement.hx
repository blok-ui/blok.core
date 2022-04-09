package blok.ui;

import blok.core.Debug;

class ObjectWithChildrenElement extends ObjectElement {
  var children:Array<Element> = [];

  public function getChildren() {
    return children.copy();
  }

  function performBuild(previousWidget:Null<Widget>) {
    enqueueEffects();
    
    if (previousWidget == null) {
      object = createObject();
      platform.insertObject(object, slot, findAncestorObject);
      initializeChildren();
    } else {
      if (previousWidget != widget) updateObject(previousWidget);
      rebuildChildren();
    }
  }

  function performHydrate(cursor:HydrationCursor) {
    enqueueEffects();

    object = cursor.current();
    Debug.assert(object != null);
    updateObject(object);

    var widgets = (cast widget:ObjectWidget).getChildren();
    var objects = cursor.currentChildren();
    var children:Array<Element> = [];
    var previous:Null<Element> = null;

    for (i in 0...widgets.length) {
      var element = hydrateElementForWidget(objects, widgets[i], createSlotForChild(i, previous));
      children.push(element);
      previous = element;
    }

    Debug.assert(objects.current() == null);
    
    cursor.next();

    this.children = children;
  }

  function initializeChildren() {
    var widgets = (cast widget:ObjectWidget).getChildren();
    var previous:Null<Element> = null;
    var children:Array<Element> = [];
    
    for (i in 0...widgets.length) {
      var element = createElementForWidget(widgets[i], createSlotForChild(i, previous));
      children.push(element);
      previous = element;
    }

    this.children = children;
  }

  function rebuildChildren() {
    var widgets = (cast widget:ObjectWidget).getChildren();
    children = diffChildren(children, widgets);
  }

  override function updateSlot(slot:Slot) {
    var previousSlot = this.slot;
    this.slot = slot;
    platform.moveObject(object, previousSlot, slot, findAncestorObject);
  }

  override function dispose() {
    if (object != null) platform.removeObject(object, slot);
    
    super.dispose();

    object = null;
    children = [];
  }

  function visitChildren(visitor:ElementVisitor) {
    for (child in children) visitor.visit(child);
  }
}

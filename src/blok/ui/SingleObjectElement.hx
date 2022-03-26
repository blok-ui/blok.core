package blok.ui;

class SingleObjectElement extends ObjectElement {
  var object:Null<Dynamic> = null;
  var children:Array<Element> = [];

  override function getObject():Dynamic {
    return object;
  }

  public function createObject():Dynamic {
    return platform.createObjectForWidget(cast widget);
  }

  public function updateObject(?oldWidget:Widget) {
    object = platform.updateObject(object, cast widget, cast oldWidget);
  }

  public function getChildren() {
    return children.copy();
  }

  function buildElement(previousWidget:Null<Widget>) {
    if (previousWidget == null) {
      object = createObject();
      platform.insertObject(object, slot, findAncestorObject);
      initializeChildren();
    } else {
      if (previousWidget != widget) updateObject(previousWidget);
      rebuildChildren();
    }
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

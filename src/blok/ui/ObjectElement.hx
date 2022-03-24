package blok.ui;

class ObjectElement extends Element {
  var object:Null<Dynamic> = null;
  var children:Array<Element> = [];

  public function createObject():Dynamic {
    return (cast widget:ObjectWidget).createObject();
  }

  public function updateObject(?oldWidget:Widget) {
    object = (cast widget:ObjectWidget).updateObject(object, oldWidget);
  }

  public function getChildren() {
    return children.copy();
  }

  override function getObject():Dynamic {
    return object;
  }

  function buildElement(previousWidget:Null<Widget>) {
    if (previousWidget == null) {
      object = createObject();
      platform.insert(object, slot, findAncestorObject);
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
      var element = createElementForWidget(widgets[i], new Slot(i, previous));
      children.push(element);
      previous = element;
    }

    this.children = children;
  }

  function rebuildChildren() {
    lifecycle = Building;
    var widgets = (cast widget:ObjectWidget).getChildren();
    children = diffChildren(children, widgets);
  }

  override function updateSlot(slot:Slot) {
    var oldSlot = this.slot;
    super.updateSlot(slot);
    platform.move(object, oldSlot, slot, findAncestorObject);
  }

  override function dispose() {
    if (object != null) platform.remove(object, slot);
    
    super.dispose();

    object = null;
    children = [];
  }

  function findAncestorObject():Dynamic {
    return switch findAncestorOfType(ObjectElement) {
      case None: switch findAncestorOfType(RootElement) {
        case None: throw 'Unable to find ObjectElement or RootElement ancestor.';
        case Some(root): root.getObject();
      }
      case Some(root): root.getObject();
    }
  }

  function visitChildren(visitor:ElementVisitor) {
    for (child in children) visitor.visit(child);
  }
}

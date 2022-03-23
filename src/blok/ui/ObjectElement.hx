package blok.ui;

import blok.core.Debug;

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

  override function mount(parent:Null<Element>, ?slot:Slot) {
    super.mount(parent, slot);

    lifecycle = Building;
    object = createObject();
    platform.insert(object, slot, findAncestorObject);

    var widgets = (cast widget:ObjectWidget).getChildren();
    var previous:Null<Element> = null;
    var children:Array<Element> = [];
    
    for (i in 0...widgets.length) {
      var element = createElementForWidget(widgets[i], new Slot(i, previous));
      children.push(element);
      previous = element;
    }

    this.children = children;
    lifecycle = Valid;
  }

  override function update(widget:Widget) {
    if (this.widget == widget) return;

    var oldWidget = this.widget;

    super.update(widget);

    updateObject(oldWidget);
    rebuildChildren();
  }

  public function rebuildElement() {
    if (lifecycle != Invalid) return;
    updateObject(widget);
    rebuildChildren();
  }

  function rebuildChildren() {
    Debug.assert(lifecycle != Building);
    lifecycle = Building;
    var widgets = (cast widget:ObjectWidget).getChildren();
    children = diffChildren(children, widgets);
    lifecycle = Valid;
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

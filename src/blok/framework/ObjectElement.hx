package blok.framework;

abstract class ObjectElement extends Element {
  var object:Null<Dynamic> = null;
  var children:Array<Element> = [];

  abstract public function createObject():Dynamic;
  abstract public function updateObject(?oldWidget:Widget):Void;

  public function getChildren() {
    return children.copy();
  }

  override function getObject():Dynamic {
    return object;
  }

  override function update(widget:Widget) {
    if (this.widget == widget) return;

    var oldWidget = this.widget;

    super.update(widget);

    updateObject(oldWidget);
    var widgets = (cast widget:ObjectWidget).getChildren();

    children = diffChildren(children, widgets);
  }

  override function updateSlot(slot:Slot) {
    var oldSlot = this.slot;
    super.updateSlot(slot);
    platform.move(object, oldSlot, slot);
  }

  override function mount(parent:Null<Element>, ?slot:Slot) {
    super.mount(parent, slot);

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
  }

  override function dispose() {
    if (object != null) platform.remove(object, slot);
    
    super.dispose();

    object = null;
    children = [];
  }

  function findAncestorObject() {
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

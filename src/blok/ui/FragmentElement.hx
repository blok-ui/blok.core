package blok.ui;

class FragmentElement extends Element {
  var children:Array<Element>;
  var marker:Dynamic;

  override function getObject():Dynamic {
    var child:Element = null;

    // First, we need to find our last child.
    visitChildren(c -> child = c);

    // If the child is null...
    if (child == null) {
      // ...return our marker.
      if (marker == null) {
        marker = platform.createPlaceholderObjectForWidget(widget);
        platform.insertObject(marker, slot, findAncestorObject);
      }
      return marker;
    }

    // Otherwise, we need the last object in our Fragment. This will
    // ensure that the Slot for the next element will be placed 
    // after this one.
    return child.getObject();
  }

  public function buildElement(previousWidget:Null<Widget>) {
    if (previousWidget == null) {
      initializeChildren();
    } else {
      rebuildChildren();
    }
  }

  public function visitChildren(visitor:ElementVisitor) {
    if (children != null) {
      for (child in children) visitor.visit(child);
    }
  }

  function initializeChildren() {
    var widgets = (cast widget:FragmentWidget).getChildren();
    var previous:Null<Element> = slot != null ? slot.previous : null;
    var children:Array<Element> = [];
    
    for (i in 0...widgets.length) {
      var element = createElementForWidget(widgets[i], createSlotForChild(i, previous));
      children.push(element);
      previous = element;
    }

    this.children = children;
  }

  function rebuildChildren() {
    var widgets = (cast widget:FragmentWidget).getChildren();
    children = diffChildren(children, widgets);
  }

  override function updateSlot(slot:Slot) {
    var previousSlot = this.slot;
    this.slot = slot;
    if (marker != null) platform.moveObject(marker, previousSlot, slot, findAncestorObject);
    for (i in 0...children.length) {
      var previous = i == 0 ? slot.previous : children[i - 1];
      children[i].updateSlot(createSlotForChild(i, previous));
    }
  }

  override function createSlotForChild(localIndex:Int, previous:Null<Element>):Slot {
    var index = slot != null ? slot.index : 0;
    return new FragmentSlot(index, localIndex, previous);
  }

  override function dispose() {
    super.dispose();
    if (marker != null) platform.removeObject(marker, slot);
  }
}
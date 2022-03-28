package blok.ui;

import blok.core.UniqueId;

class FragmentWidget extends Widget {
  static final type = new UniqueId();

  final children:Array<Widget>;

  public function new(children, ?key) {
    super(key);
    this.children = children;
  }

  public inline function getChildren() {
    return children;
  }

  public function getWidgetType():UniqueId {
    return type;
  }

  public function createElement():Element {
    return new FragmentElement(this);
  }
}

class FragmentSlot extends Slot {
  public final localIndex:Int;

  public function new(index, localIndex, previous) {
    super(index, previous);
    this.localIndex = localIndex;
  }

  override function indexChanged(other:Slot):Bool {
    if (other.index != index) return true;
    if (other is FragmentSlot) {
      var otherFragment:FragmentSlot = cast other;
      return localIndex != otherFragment.localIndex;
    }
    return false;
  }
}


class FragmentElement extends Element {
  var children:Array<Element>;
  var marker:Dynamic;

  override function getObject():Dynamic {
    var child:Element = null;

    visitChildren(c -> child = c);

    if (child == null) {
      if (marker == null) {
        marker = platform.createPlaceholderObject(widget);
        platform.insertObject(marker, slot, findAncestorObject);
      }
      return marker;
    }

    return child.getObject();
  }

  public function performBuild(previousWidget:Null<Widget>) {
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

  function performHydrate(cursor:HydrationCursor) {
    var widgets = (cast widget:FragmentWidget).getChildren();
    var previous:Null<Element> = slot != null ? slot.previous : null;
    var children:Array<Element> = [];

    if (widgets.length == 0) {
      marker = platform.createPlaceholderObject(widget);
      platform.insertObject(marker, slot, findAncestorObject);
      cursor.move(marker);
      cursor.next();
      return;
    }
    
    for (i in 0...widgets.length) {
      var element = hydrateElementForWidget(cursor, widgets[i], createSlotForChild(i, previous));
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

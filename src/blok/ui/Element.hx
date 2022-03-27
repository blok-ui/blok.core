package blok.ui;

import blok.core.Debug;
import blok.core.DisposableHost;
import blok.core.Disposable;
import haxe.ds.Option;

enum ElementStatus {
  Pending;
  Active;
  Disposed;
}

enum ElementLifecycle {
  Valid;
  Invalid;
  Building;
}

@:allow(blok.ui)
abstract class Element implements Disposable implements DisposableHost {
  var widget:Widget;
  var slot:Null<Slot> = null;
  var status:ElementStatus = Pending;
  var lifecycle:ElementLifecycle = Invalid;
  var parent:Null<Element> = null;
  var platform:Null<Platform> = null;
  final disposables:Array<Disposable> = [];

  public function new(widget) {
    this.widget = widget;
  }

  public function mount(parent:Null<Element>, ?slot:Slot) {
    performSetup(parent, slot);
    lifecycle = Building;
    performBuild(null);
    lifecycle = Valid;
  }

  public function hydrate(cursor:HydrationCursor, parent:Null<Element>, ?slot:Slot) {
    performSetup(parent, slot);
    lifecycle = Building;
    performHydrate(cursor);
    lifecycle = Valid;
  }

  function performSetup(parent:Null<Element>, ?slot:Slot) {
    Debug.assert(status == Pending, 'Attempted to mount an already mounted Element');
    Debug.assert(lifecycle == Invalid);

    this.parent = parent;
    this.slot = slot;
    platform = this.parent.platform;
    status = Active;
  }
  
  public function update(widget:Widget) {
    Debug.assert(lifecycle != Building);

    lifecycle = Building;
    var previousWidget = this.widget;
    this.widget = widget;
    performBuild(previousWidget);
    lifecycle = Valid;
  }

  public function rebuild() {
    Debug.assert(lifecycle != Building);
    
    if (lifecycle != Invalid) return;

    lifecycle = Building;
    performBuild(widget);
    lifecycle = Valid;
  }

  public function dispose() {
    Debug.assert(status == Active);
    
    visitChildren(child -> child.dispose());

    for (disposable in disposables) disposable.dispose();

    status = Disposed;
    parent = null;
    platform = null;
    widget = null;
    slot = null;
  }

  public function invalidate() {
    Debug.assert(status == Active);
    Debug.assert(lifecycle == Valid);

    lifecycle = Invalid;
    platform.scheduleForRebuild(this);
  }

  abstract function performHydrate(cursor:HydrationCursor):Void;
  abstract function performBuild(previousWidget:Null<Widget>):Void;
  abstract public function visitChildren(visitor:ElementVisitor):Void;

  public function addDisposable(disposable:Disposable) {
    disposables.push(disposable);
  }

  public final inline function getWidget():Widget {
    return widget;
  }

  public function findAncestorOfType<T:Element>(kind:Class<T>):Option<T> {
    if (parent == null) {
      if (Std.isOfType(this, kind)) return Some(cast this);
      return None;
    }

    return switch (Std.downcast(parent, kind):Null<T>) {
      case null: parent.findAncestorOfType(kind);
      case found: Some(cast found);
    }
  }

  function findAncestorObject():Dynamic {
    return switch findAncestorOfType(ObjectElement) {
      case None: throw 'Unable to find ObjectElement ancestor.';
      case Some(root): root.getObject();
    }
  }

  public function getObject():Dynamic {
    var object:Dynamic = null;
    
    function visit(element:Element) {
      Debug.assert(object == null, 'Element has more than one objects');
      if (element.status == Disposed) return;
      switch Std.downcast(element, ObjectElement) {
        case null: element.visitChildren(visit);
        case el: object = el.getObject();
      }
    }
    visit(this);
    
    Debug.assert(object != null, 'Element does not have an object');

    return object;
  }

  function updateChild(?child:Element, ?widget:Widget, ?slot:Slot):Null<Element> {
    if (widget == null) {
      if (child != null) removeChild(child);
      return null;
    }
    
    return if (child != null) {
      if (child.widget == widget) {
        if (child.slot != slot) updateSlotForChild(child, slot);
        child;
      } else if (child.widget.shouldBeUpdated(widget)) {
        if (child.slot != slot) updateSlotForChild(child, slot);
        child.update(widget);
        child;
      } else {
        removeChild(child);
        createElementForWidget(widget, slot);
      }
    } else {
      createElementForWidget(widget, slot);
    }
  }

  function updateSlot(slot:Slot) {
    this.slot = slot;
    visitChildren(child -> child.updateSlot(slot));
  }

  function diffChildren(oldChildren:Array<Element>, newWidgets:Array<Widget>) {
    // Almost entirely taken from: https://github.com/flutter/flutter/blob/6af40a7004f886c8b8b87475a40107611bc5bb0a/packages/flutter/lib/src/widgets/framework.dart#L5761
    var newHead = 0;
    var oldHead = 0;
    var newTail = newWidgets.length - 1;
    var oldTail = oldChildren.length - 1;
    var previousChild:Null<Element> = null;
    var newChildren = [];

    // Scan from the top of the list, syncing until we can't anymore.
    while ((oldHead <= oldTail) && (newHead <= newTail)) {
      var oldChild = oldChildren[oldHead];
      var newWidget = newWidgets[newHead];
      if (oldChild == null || !oldChild.widget.shouldBeUpdated(newWidget)) {
        break;
      }

      var newChild = updateChild(oldChild, newWidget, createSlotForChild(newHead, previousChild));
      newChildren[newHead] = newChild;
      previousChild = newChild;
      newHead += 1;
      oldHead += 1;
    }

    // Scan from the bottom, without syncing.
    while ((oldHead <= oldTail) && (newHead <= newTail)) {
      var oldChild = oldChildren[oldTail];
      var newWidget = newWidgets[newTail];
      if (oldChild == null || !oldChild.widget.shouldBeUpdated(newWidget)) {
        break;
      }
      oldTail -= 1;
      newTail -= 1;
    }

    // Scan the middle.
    var hasOldChildren = oldHead <= oldTail;
    var oldKeyedChildren = null;

    // If we still have old children, go through the array and check
    // if any have keys. If they don't, remove them.
    if (hasOldChildren) {
      oldKeyedChildren = Key.createMap();
      while (oldHead <= oldTail) {
        var oldChild = oldChildren[oldHead];
        if (oldChild != null) {
          if (oldChild.widget.key != null) {
            oldKeyedChildren.set(oldChild.widget.key, oldChild);
          } else {
            removeChild(oldChild);
          }
        }
        oldHead += 1;
      }
    }

    // Sync/update any new elements. If we have more children than before
    // this is where things will happen.
    while (newHead <= newTail) {
      var oldChild:Element = null;
      var newWidget = newWidgets[newHead];

      // Check if we already have an element with a matching key.
      if (hasOldChildren) {
        var key = newWidget.key;
        if (key != null) {
          oldChild = oldKeyedChildren.get(key);
          if (oldChild != null) {
            if (oldChild.widget.shouldBeUpdated(newWidget)) {
              // We do -- remove a keyed child from the list so we don't 
              // unsync it later.
              oldKeyedChildren.remove(key);
            } else {
              // We don't -- ignore it for now.
              oldChild = null;
            }
          }
        }
      }

      var newChild = updateChild(oldChild, newWidget, createSlotForChild(newHead, previousChild));
      newChildren[newHead] = newChild;
      previousChild = newChild;
      newHead += 1;
    }

    newTail = newWidgets.length - 1;
    oldTail = oldChildren.length - 1;

    // Update the bottom of the list.
    while ((oldHead <= oldTail) && (newHead <= newTail)) {
      var oldChild = oldChildren[oldHead];
      var newWidget = newWidgets[newHead];
      var newChild = updateChild(oldChild, newWidget, createSlotForChild(newHead, previousChild));
      newChildren[newHead] = newChild;
      previousChild = newChild;
      newHead += 1;
      oldHead += 1;
    }

    // Clean up any remaining children. At this point, we should only
    // have to worry about keyed elements that are lingering around.
    if (hasOldChildren && (oldKeyedChildren != null && oldKeyedChildren.isNotEmpty())) {
      oldKeyedChildren.each((_, element) -> removeChild(element));
    }

    return newChildren;
  }

  function updateSlotForChild(child:Element, slot:Slot) {
    child.updateSlot(slot);
  }

  function removeChild(child:Element) {
    child.dispose();
  }

  function createElementForWidget(widget:Widget, ?slot:Slot) {
    var element = widget.createElement();
    element.mount(this, slot);
    return element;
  }

  function hydrateElementForWidget(cursor:HydrationCursor, widget:Widget, ?slot:Slot) {
    var element = widget.createElement();
    element.hydrate(cursor, this, slot);
    return element;
  }

  function createSlotForChild(index:Int, previous:Null<Element>) {
    return new Slot(index, previous);
  }
}

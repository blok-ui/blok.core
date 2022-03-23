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

  public function addDisposable(disposable:Disposable) {
    disposables.push(disposable);
  }

  public final inline function getWidget():Widget {
    return widget;
  }

  public function invalidateElement() {
    Debug.assert(status == Active);
    Debug.assert(lifecycle == Valid);

    lifecycle = Invalid;
    platform.scheduleForRebuild(this);
  }

  abstract public function rebuildElement():Void;
  abstract public function visitChildren(visitor:ElementVisitor):Void;

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

  public function getObject():Dynamic {
    var object:Dynamic = null;
    
    function visit(element:Element) {
      Debug.assert(object == null); // Check we don't find more than one object.
      if (element.status == Disposed) return;
      switch Std.downcast(element, ObjectElement) {
        case null: element.visitChildren(visit);
        case el: object = el.getObject();
      }
    }
    visit(this);
    
    Debug.assert(object != null, 'No object could be found');

    return object;
  }

  public function mount(parent:Null<Element>, ?slot:Slot) {
    this.parent = parent;
    this.slot = slot;
    platform = this.parent.platform;
    status = Active;
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
  
  public function update(widget:Widget) {
    Debug.assert(lifecycle != Building);
    this.widget = widget;
    lifecycle = Valid;
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
      } else if (child.widget.canBeUpdated(widget)) {
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
  }

  function diffChildren(oldChildren:Array<Element>, newWidgets:Array<Widget>) {
    // More or less taken from: https://github.com/flutter/flutter/blob/6af40a7004f886c8b8b87475a40107611bc5bb0a/packages/flutter/lib/src/widgets/framework.dart#L5761
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
      if (oldChild == null || !oldChild.widget.canBeUpdated(newWidget)) {
        break;
      }

      var newChild = updateChild(oldChild, newWidget, new Slot(newHead, previousChild));
      newChildren[newHead] = newChild;
      previousChild = newChild;
      newHead += 1;
      oldHead += 1;
    }

    // Scan from the bottom, without syncing.
    while ((oldHead <= oldTail) && (newHead <= newTail)) {
      var oldChild = oldChildren[oldTail];
      var newWidget = newWidgets[newTail];
      if (oldChild == null || !oldChild.widget.canBeUpdated(newWidget)) {
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
            if (oldChild.widget.canBeUpdated(newWidget)) {
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

      var newChild = updateChild(oldChild, newWidget, new Slot(newHead, previousChild));
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
      var newChild = updateChild(oldChild, newWidget, new Slot(newHead, previousChild));
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
    function visit(element:Element) {
      element.updateSlot(slot);
      if (!(element is ObjectElement)) {
        element.visitChildren(visit);
      }
    }
    visit(child);
  }

  function removeChild(child:Element) {
    child.dispose();
  }

  function createElementForWidget(widget:Widget, ?slot:Slot) {
    var element = widget.createElement();
    element.mount(this, slot);
    return element;
  }
}

package blok.diffing;

import blok.debug.Debug;
import blok.ui.*;

function updateChild(
  parent:ComponentBase,
  child:Null<ComponentBase>,
  node:Null<VNode>,
  slot:Null<Slot>
):Null<ComponentBase> {
  if (node == null) {
    if (child != null) child.dispose();
    return null;
  }

  return if (child != null) {
    if (child.__node == node) {
      if (child.__slot.indexChanged(slot)) child.updateSlot(slot);
      child;
    } else if (canBeUpdatedByNode(child, node)) {
      if (child.__slot.indexChanged(slot)) child.updateSlot(slot);
      child.update(node);
      child;
    } else {
      child.dispose();
      createComponentForVNode(parent, node, slot);
    }
  } else {
    createComponentForVNode(parent, node, slot);
  }
}

function diffChildren(
  parent:ComponentBase,
  oldChildren:Array<ComponentBase>,
  newNodes:Array<VNode>
):Array<ComponentBase> {
  var newHead = 0;
  var oldHead = 0;
  var newTail = newNodes.length - 1;
  var oldTail = oldChildren.length - 1;
  var previousChild:Null<ComponentBase> = null;
  var newChildren:Array<Null<ComponentBase>> = [];

  // Scan from the top of the list, syncing until we can't anymore.
  while ((oldHead <= oldTail) && (newHead <= newTail)) {
    var oldChild = oldChildren[oldHead];
    var newNode = newNodes[newHead];
    if (oldChild == null || !canBeUpdatedByNode(oldChild, newNode)) {
      break;
    }

    var newChild = updateChild(parent, oldChild, newNode, parent.createSlot(newHead, previousChild));
    newChildren[newHead] = newChild;
    previousChild = newChild;
    newHead += 1;
    oldHead += 1;
  }

  // Scan from the bottom, without syncing.
  while ((oldHead <= oldTail) && (newHead <= newTail)) {
    var oldChild = oldChildren[oldTail];
    var newNode = newNodes[newTail];
    if (oldChild == null || !canBeUpdatedByNode(oldChild, newNode)) {
      break;
    }
    oldTail -= 1;
    newTail -= 1;
  }

  // Scan the middle.
  var hasOldChildren = oldHead <= oldTail;
  var oldKeyedChildren:Null<KeyMap<ComponentBase>> = null;

  // If we still have old children, go through the array and check
  // if any have keys. If they don't, remove them.
  if (hasOldChildren) {
    oldKeyedChildren = new KeyMap();
    while (oldHead <= oldTail) {
      var oldChild = oldChildren[oldHead];
      if (oldChild != null) {
        if (oldChild.__node.key != null) {
          oldKeyedChildren.set(oldChild.__node.key, oldChild);
        } else {
          oldChild.dispose();
        }
      }
      oldHead += 1;
    }
  }

  // Sync/update any new elements. If we have more children than before
  // this is where things will happen.
  while (newHead <= newTail) {
    var oldChild:Null<ComponentBase> = null;
    var newNode = newNodes[newHead];

    // Check if we already have an element with a matching key.
    if (hasOldChildren) {
      var key = newNode.key;
      if (key != null) {
        if (oldKeyedChildren == null) {
          throw 'assert'; // This should never happen
        }

        oldChild = oldKeyedChildren.get(key);
        if (oldChild != null) {
          if (canBeUpdatedByNode(oldChild, newNode)) {
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

    var newChild = updateChild(parent, oldChild, newNode, parent.createSlot(newHead, previousChild));
    newChildren[newHead] = newChild;
    previousChild = newChild;
    newHead += 1;
  }

  newTail = newNodes.length - 1;
  oldTail = oldChildren.length - 1;

  // Update the bottom of the list.
  while ((oldHead <= oldTail) && (newHead <= newTail)) {
    var oldChild = oldChildren[oldHead];
    var newNode = newNodes[newHead];
    var newChild = updateChild(parent, oldChild, newNode, parent.createSlot(newHead, previousChild));
    newChildren[newHead] = newChild;
    previousChild = newChild;
    newHead += 1;
    oldHead += 1;
  }

  // Clean up any remaining children. At this point, we should only
  // have to worry about keyed elements that are lingering around.
  if (hasOldChildren && (oldKeyedChildren != null && oldKeyedChildren.isNotEmpty())) {
    oldKeyedChildren.each((_, element) -> element.dispose());
  }

  assert(!Lambda.exists(newChildren, el -> el == null));

  return cast newChildren;
}

function hydrateChildren(parent:ComponentBase, cursor:Cursor, children:Array<VNode>) {
  var previous:Null<ComponentBase> = null;
  return [ for (i => node in children) {
    var child = node.createComponent();
    child.hydrate(cursor, parent, parent.createSlot(i, previous));
    previous = child;
    child;
  } ];
}

private function createComponentForVNode(parent:ComponentBase, node:VNode, ?slot:Slot) {
  var element = node.createComponent();
  element.mount(parent, slot);
  return element;
}

private function canBeUpdatedByNode(component:ComponentBase, node:VNode) {
  return component.canBeUpdatedByNode(node) && component.__node.key == node.key;
}

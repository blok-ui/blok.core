package blok.engine;

import blok.debug.Debug;

function updateView(adaptor:Adaptor, parent:View, view:Null<View>, node:Null<VNode>, slot:Null<Slot>):Null<View> {
	if (node == null) {
		if (view != null) view.dispose();
		return null;
	}

	if (view != null && canBeUpdatedByNode(view, node)) {
		view.remount(adaptor, parent, node, slot);
		return view;
	}

	var newView = node.createView();

	if (view == null) {
		newView.mount(adaptor, parent, slot);
		return newView;
	}

	newView.replace(adaptor, parent, view, slot);
	return newView;
}

function diffChildren(adaptor:Adaptor, parent:View, oldViews:Array<View>, newNodes:Array<VNode>):Array<View> {
	var newHead = 0;
	var oldHead = 0;
	var newTail = newNodes.length - 1;
	var oldTail = oldViews.length - 1;
	var previousView:Null<View> = null;
	var newViews:Array<Null<View>> = [];

	// Scan from the top of the list, syncing until we can't anymore.
	while ((oldHead <= oldTail) && (newHead <= newTail)) {
		var oldView = oldViews[oldHead];
		var newNode = newNodes[newHead];
		if (oldView == null || !canBeUpdatedByNode(oldView, newNode)) {
			break;
		}

		var newView = updateView(adaptor, parent, oldView, newNode, parent.createSlot(newHead, previousView));
		newViews[newHead] = newView;
		previousView = newView;
		newHead += 1;
		oldHead += 1;
	}

	// Scan from the bottom, without syncing.
	while ((oldHead <= oldTail) && (newHead <= newTail)) {
		var oldView = oldViews[oldTail];
		var newNode = newNodes[newTail];
		if (oldView == null || !canBeUpdatedByNode(oldView, newNode)) {
			break;
		}
		oldTail -= 1;
		newTail -= 1;
	}

	// Scan the middle.
	var hasOldViews = oldHead <= oldTail;
	var oldKeyedViews:Null<KeyMap<View>> = null;

	// If we still have old children, go through the array and check
	// if any have keys. If they don't, remove them.
	if (hasOldViews) {
		oldKeyedViews = new KeyMap();
		while (oldHead <= oldTail) {
			var oldView = oldViews[oldHead];
			if (oldView != null) {
				if (oldView.__node.key != null) {
					oldKeyedViews.set(oldView.__node.key, oldView);
				} else {
					oldView.dispose();
				}
			}
			oldHead += 1;
		}
	}

	// Sync/update any new views. If we have more children than before
	// this is where things will happen.
	while (newHead <= newTail) {
		var oldView:Null<View> = null;
		var newNode = newNodes[newHead];

		// Check if we already have an view with a matching key.
		if (hasOldViews) {
			var key = newNode.key;
			if (key != null) {
				if (oldKeyedViews == null) {
					throw 'assert'; // This should never happen
				}

				oldView = oldKeyedViews.get(key);
				if (oldView != null) {
					if (canBeUpdatedByNode(oldView, newNode)) {
						// We do -- remove a keyed child from the list so we don't
						// unsync it later.
						oldKeyedViews.remove(key);
					} else {
						// We don't -- ignore it for now.
						oldView = null;
					}
				}
			}
		}

		var newView = updateView(adaptor, parent, oldView, newNode, parent.createSlot(newHead, previousView));
		newViews[newHead] = newView;
		previousView = newView;
		newHead += 1;
	}

	newTail = newNodes.length - 1;
	oldTail = oldViews.length - 1;

	// Update the bottom of the list.
	while ((oldHead <= oldTail) && (newHead <= newTail)) {
		var oldView = oldViews[oldHead];
		var newNode = newNodes[newHead];
		var newView = updateView(adaptor, parent, oldView, newNode, parent.createSlot(newHead, previousView));
		newViews[newHead] = newView;
		previousView = newView;
		newHead += 1;
		oldHead += 1;
	}

	// Clean up any remaining children. At this point, we should only
	// have to worry about keyed views that are lingering around.
	if (hasOldViews && (oldKeyedViews != null && oldKeyedViews.isNotEmpty())) {
		oldKeyedViews.each((_, view) -> view.dispose());
	}

	assert(!Lambda.exists(newViews, el -> el == null));

	return cast newViews;
}

function hydrateChildren(parent:View, cursor:Cursor, children:Array<VNode>) {
	var previous:Null<View> = null;
	return [for (i => node in children) {
		var child = node.createView();
		child.hydrate(cursor, parent.getAdaptor(), parent, parent.createSlot(i, previous));
		previous = child;
		child;
	}];
}

private function canBeUpdatedByNode(component:View, node:VNode) {
	return component.canBeUpdatedByNode(node) && component.__node.key == node.key;
}

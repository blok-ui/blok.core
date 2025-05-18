package blok.engine;

import blok.debug.Debug;

class ViewListReconciler {
	final parent:View;
	final adaptor:Adaptor;

	var children:Array<View> = [];

	public function new(parent, adaptor) {
		this.parent = parent;
		this.adaptor = adaptor;
	}

	public function reconcile(newNodes:Array<Node>, cursor:Cursor, ?hydrate:Bool):Result<Array<View>, ViewError> {
		var newHead = 0;
		var oldHead = 0;
		var newTail = newNodes.length - 1;
		var oldTail = children.length - 1;
		var previousView:Null<View> = null;
		var oldViews = children.copy();
		var newViews:Array<Null<View>> = [];

		function updateView(node:Null<Node>, view:Null<View>):Result<Null<View>, ViewError> {
			if (node == null) {
				if (view != null) view.remove(cursor);
				return Ok(null);
			}

			if (view != null && view.currentNode().matches(node)) {
				view.update(Some(parent), node, cursor);
				return Ok(view);
			}

			return node
				.createView(Some(parent), adaptor)
				.insert(cursor, hydrate)
				.always(() -> view?.remove(cursor));
		}

		// Scan from the top of the list, syncing until we can't anymore.
		while ((oldHead <= oldTail) && (newHead <= newTail)) {
			var oldView = oldViews[oldHead];
			var newNode = newNodes[newHead];
			if (oldView == null || !oldView.currentNode().matches(newNode)) {
				break;
			}

			var newView = updateView(newNode, oldView).orReturn();
			newViews[newHead] = newView;
			previousView = newView;
			newHead += 1;
			oldHead += 1;
		}

		// Scan from the bottom, without syncing.
		while ((oldHead <= oldTail) && (newHead <= newTail)) {
			var oldView = oldViews[oldTail];
			var newNode = newNodes[newTail];
			if (oldView == null || !oldView.currentNode().matches(newNode)) {
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
					if (oldView.currentNode().key != null) {
						oldKeyedViews.set(oldView.currentNode().key, oldView);
					} else {
						oldView.remove(cursor);
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
						if (oldView.currentNode().matches(newNode)) {
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

			var newView = updateView(newNode, oldView).orReturn();
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
			var newView = updateView(newNode, oldView).orReturn();
			newViews[newHead] = newView;
			previousView = newView;
			newHead += 1;
			oldHead += 1;
		}

		// Clean up any remaining children. At this point, we should only
		// have to worry about keyed views that are lingering around.
		if (hasOldViews && (oldKeyedViews != null && oldKeyedViews.isNotEmpty())) {
			oldKeyedViews.each((_, view) -> view.remove(cursor));
		}

		assert(!Lambda.exists(newViews, el -> el == null));

		children = newViews;

		return Ok(children);
	}

	public function remove(cursor:Cursor):Result<Nothing, ViewError> {
		var toDispose = children.copy();
		children = [];
		for (child in toDispose) child.remove(cursor).orReturn();
		return Ok(Nothing);
	}

	public function each(visitor:(view:View) -> Bool) {
		for (child in children) if (!visitor(child)) return;
	}
}

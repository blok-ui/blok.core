package blok.engine;

class ViewReconciler {
	final parent:View;
	final adaptor:Adaptor;
	var view:Maybe<View> = None;

	public function new(parent, adaptor) {
		this.parent = parent;
		this.adaptor = adaptor;
	}

	public function get() {
		return view;
	}

	public function insert(node:Node, cursor:Cursor, ?hydrate):Result<View, ViewError> {
		if (view != None) return Error(ViewAlreadyExists(parent));

		var newView = node.createView(Some(parent), adaptor);

		// Note: It's important that the new view is stored by the ViewReconciler
		// before we do anything that could fail (like inserting it). This is especially
		// important for the BoundaryView which will need to have access to this new View
		// even if it fails to insert properly.
		this.view = Some(newView);

		newView.insert(cursor, hydrate).orReturn();
		return Ok(newView);
	}

	public function reconcile(node:Node, cursor:Cursor):Result<View, ViewError> {
		return switch view {
			case Some(view) if (view.currentNode().matches(node)):
				view.update(Some(parent), node, cursor);
			case Some(previousView):
				var newView = node.createView(Some(parent), adaptor);

				this.view = Some(newView);

				newView.insert(cursor).orReturn();
				previousView.remove(cursor);

				Ok(newView);
			case None:
				var newView = node.createView(Some(parent), adaptor);

				this.view = Some(newView);

				newView.insert(cursor);
		}
	}

	public function remove(cursor:Cursor):Result<Nothing, ViewError> {
		view.inspect(view -> view.remove(cursor));
		view = None;
		return Ok(Nothing);
	}
}

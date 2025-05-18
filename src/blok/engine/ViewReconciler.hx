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

		view = Some(node.createView(Some(parent), adaptor));
		view.unwrap().insert(cursor, hydrate).orReturn();

		return Ok(view.unwrap());
	}

	public function reconcile(node:Node, cursor:Cursor):Result<View, ViewError> {
		view = Some(switch view {
			case Some(child) if (child.currentNode().matches(node)):
				child.update(Some(parent), node, cursor).orReturn();
			case Some(child):
				var view = node.createView(Some(parent), adaptor).insert(cursor).orReturn();
				child.remove(cursor);
				view;
			case None:
				node.createView(Some(parent), adaptor).insert(cursor).orReturn();
		});

		return Ok(view.unwrap());
	}

	public function remove(cursor:Cursor):Result<Nothing, ViewError> {
		view.inspect(view -> view.remove(cursor));
		view = None;
		return Ok(Nothing);
	}
}

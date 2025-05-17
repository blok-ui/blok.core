package blok.engine;

import blok.core.*;

class FragmentView implements View implements Boundary {
	final adaptor:Adaptor;

	var disposables:Null<DisposableCollection> = null;
	var parent:Maybe<View>;
	var node:FragmentNode;
	var children:ViewListReconciler;
	var rendering:Bool = false;
	var errors:Array<() -> Void> = [];

	public function new(parent, node, adaptor) {
		this.adaptor = adaptor;
		this.parent = parent;
		this.node = node;
		this.children = new ViewListReconciler(this, adaptor);
	}

	public function capture(target:View, payload:Any) {
		if (rendering) {
			errors.push(() -> this.captureWithBoundary(target, payload));
			return;
		}
		this.captureWithBoundary(target, payload);
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return parent;
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		rendering = true;

		var nodes = node.children;
		if (nodes.length == 0) nodes = [Placeholder.node()];

		this.children.reconcile(nodes, cursor, hydrate)
			.always(() -> rendering = false)
			.always(() -> {
				if (errors.length > 0) {
					for (lazy in errors) lazy();
					errors = [];
				}
			})
			.orReturn();
		return Ok(this);
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		rendering = true;

		this.parent = parent;
		this.node = this.node
			.replaceWith(node)
			.mapError(node -> ViewError.ViewIncorrectNodeType(this, node))
			.orReturn();

		var nodes = this.node.children;
		if (nodes.length == 0) nodes = [Placeholder.node()];

		children.reconcile(nodes, cursor)
			.always(() -> rendering = false)
			.always(() -> {
				if (errors.length > 0) {
					for (lazy in errors) lazy();
					errors = [];
				}
			})
			.orReturn();

		return Ok(this);
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		disposables?.dispose();
		this.children.remove(cursor).orReturn();
		return Ok(this);
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		this.children.each(visitor);
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		children.each(child -> {
			child.visitPrimitives(visitor);
			true;
		});
	}

	public function addDisposable(disposable:DisposableItem) {
		if (disposables == null) disposables = new DisposableCollection();
		disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		disposables?.removeDisposable(disposable);
	}
}

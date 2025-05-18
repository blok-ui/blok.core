package blok.engine;

import blok.core.*;

class PortalView implements View {
	final adaptor:Adaptor;
	final portal:ViewReconciler;

	var disposables:Null<DisposableCollection> = null;
	var parent:Maybe<View>;
	var node:PortalNode;

	public function new(parent, node, adaptor) {
		this.parent = parent;
		this.node = node;
		this.adaptor = adaptor;
		this.portal = new ViewReconciler(this, adaptor);
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return parent;
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		return portal.insert(node.child, adaptor.children(node.target), hydrate);
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		this.parent = parent;

		var prevTarget = this.node.target;

		this.node = this.node.replaceWith(node)
			.mapError(node -> ViewError.IncorrectNodeType(this, node))
			.orReturn();

		return if (prevTarget != this.node.target) {
			var cursor = adaptor.children(prevTarget);
			portal.remove(cursor).orReturn();
			portal.insert(this.node.child, adaptor.children(this.node.target)).map(_ -> (this : View));
		} else {
			portal.reconcile(this.node.child, adaptor.children(this.node.target)).map(_ -> (this : View));
		}
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		portal.get().inspect(portal -> portal.visitPrimitives(visitor));
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		portal.get().inspect(portal -> visitor(portal));
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		disposables?.dispose();
		return portal
			.remove(adaptor.children(this.node.target))
			.map(_ -> (this : View));
	}

	public function addDisposable(disposable:DisposableItem) {
		if (disposables == null) disposables = new DisposableCollection();
		disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		disposables?.removeDisposable(disposable);
	}
}

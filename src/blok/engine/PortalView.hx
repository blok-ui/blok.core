package blok.engine;

import blok.core.*;

class PortalView implements View {
	final adaptor:Adaptor;
	final portal:ViewReconciler;
	final marker:ViewReconciler;

	var disposables:Null<DisposableCollection> = null;
	var parent:Maybe<View>;
	var node:PortalNode;

	public function new(parent, node, adaptor) {
		this.parent = parent;
		this.node = node;
		this.adaptor = adaptor;
		this.portal = new ViewReconciler(this, adaptor);
		this.marker = new ViewReconciler(this, adaptor);
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return parent;
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		portal.insert(node.child, adaptor.children(node.target), hydrate).orReturn();
		return marker.insert(Placeholder.node(), cursor, hydrate);
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		this.parent = parent;

		var prevTarget = this.node.target;

		this.node = this.node.replaceWith(node)
			.mapError(node -> ViewError.IncorrectNodeType(this, node))
			.orReturn();

		if (prevTarget != this.node.target) {
			var cursor = adaptor.children(prevTarget);
			portal.remove(cursor).orReturn();
			portal.insert(this.node.child, adaptor.children(this.node.target));
		} else {
			portal.reconcile(this.node.child, adaptor.children(this.node.target)).orReturn();
		}

		return marker.reconcile(Placeholder.node(), cursor);
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		marker.get().inspect(marker -> marker.visitPrimitives(visitor));
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		marker.get().inspect(marker -> visitor(marker));
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		disposables?.dispose();
		portal.remove(adaptor.children(this.node.target)).orReturn();
		return marker.remove(cursor).map(_ -> (this : View));
	}

	public function addDisposable(disposable:DisposableItem) {
		if (disposables == null) disposables = new DisposableCollection();
		disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		disposables?.removeDisposable(disposable);
	}
}

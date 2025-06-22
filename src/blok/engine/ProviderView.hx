package blok.engine;

import blok.core.*;

class ProviderView<T:Providable> implements View {
	final adaptor:Adaptor;
	final child:ViewReconciler;

	var disposables:Null<DisposableCollection>;
	var parent:Maybe<View>;
	var node:ProviderNode<T>;

	public function new(parent, node, adaptor) {
		this.parent = parent;
		this.node = node;
		this.adaptor = adaptor;
		this.child = new ViewReconciler(this, adaptor);
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return parent;
	}

	public function currentValue():T {
		return node.value;
	}

	public function match(contextId:Int) {
		return node.value.getContextId() == contextId;
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		return child.insert(node.child, cursor, hydrate).map(_ -> (this : View));
	}

	public function update(parent:Maybe<View>, incoming:Node, cursor:Cursor):Result<View, ViewError> {
		if (!this.node.matches(node)) return Error(IncorrectNodeType(this, node));

		var value = node.value;
		var incomingProvider:ProviderNode<T> = cast incoming;

		if (!incomingProvider.shared) {
			return Error(ViewError.CausedException(
				this,
				new Error(NotAcceptable, 'Only shared providers can be updated. This error indicates something odd has happened -- please submit a bug report or ensure that you are not updating the ProviderView manually.')
			));
		}

		if (value != incomingProvider.value) {
			return Error(ViewError.CausedException(this, new Error(NotAcceptable, 'Shared providers should always have the same value')));
		}

		this.node = cast incoming;
		this.parent = parent;

		return child.reconcile(node.child, cursor).map(_ -> (this : View));
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		disposables?.dispose();
		if (!node.shared) node.value.dispose();
		child.remove(cursor);
		return Ok(this);
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		child.get().inspect(view -> visitor(view));
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		child.get().inspect(view -> view.visitPrimitives(visitor));
	}

	public function addDisposable(disposable:DisposableItem) {
		if (disposables == null) disposables = new DisposableCollection();
		disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		disposables?.removeDisposable(disposable);
	}
}

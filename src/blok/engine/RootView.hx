package blok.engine;

import blok.core.*;

typedef RootState<Primitive> = {
	public final primitive:Primitive;
	public final adaptor:Adaptor;
}

class RootView<State:RootState<Primitive>, Primitive> implements View {
	final state:State;
	final child:ViewReconciler;
	final disposables:DisposableCollection = new DisposableCollection();

	var node:Node;

	public function new(state, node) {
		this.state = state;
		this.node = node;
		this.child = new ViewReconciler(this, state.adaptor);
	}

	public function getRootState():State {
		return state;
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return None;
	}

	function render():Child {
		#if debug
		return DebugBoundary.node({child: node});
		#else
		return node;
		#end
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		return child.insert(render(), cursor, hydrate);
	}

	public function update(parent:Maybe<View>, incomingNode:Node, cursor:Cursor):Result<View, ViewError> {
		node = incomingNode;
		return child.reconcile(render(), cursor);
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		disposables.dispose();
		return child.remove(cursor).map(_ -> (this : View));
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		child.get().inspect(child -> child.visitPrimitives(visitor));
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		child.get().inspect(child -> visitor(child));
	}

	public function addDisposable(disposable:DisposableItem) {
		disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		disposables.removeDisposable(disposable);
	}
}

package blok;

import blok.core.*;
import blok.engine.*;

class Root<Primitive = Any> implements ViewHost implements Disposable {
	public static function from<Primitive>(view:IntoView):Root<Primitive> {
		return maybeFrom(view).orThrow();
	}

	public static function maybeFrom<Primitive>(view:IntoView):Maybe<Root<Primitive>> {
		return view.unwrap().findAncestorOfType(RootView).map(root -> root.root);
	}

	public final primitive:Primitive;
	public final adaptor:Adaptor;
	public final root:View;

	public function new(primitive, adaptor, child:Child) {
		this.primitive = primitive;
		this.adaptor = adaptor;
		this.root = new RootView(this, child);
	}

	public function mount() {
		return root.insert(adaptor.children(primitive));
	}

	public function hydrate() {
		return root.insert(adaptor.children(primitive), true);
	}

	public function getView():View {
		return root;
	}

	public function dispose() {
		root.remove(adaptor.children(primitive)).orThrow();
	}
}

class RootView<Primitive = Any> implements View {
	public final root:Root<Primitive>;

	final child:ViewReconciler;
	final disposables:DisposableCollection = new DisposableCollection();

	var node:Node;

	public function new(root, node) {
		this.root = root;
		this.node = node;
		this.child = new ViewReconciler(this, root.adaptor);
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

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
	public final child:Node;

	public function new(primitive, adaptor, child) {
		this.primitive = primitive;
		this.adaptor = adaptor;
		this.child = child;
		this.root = new RootView(this);
	}

	public function mount() {
		// @todo: We went through all this trouble making these things return errors,
		// we should actually handle them somewhere.
		return root.insert(adaptor.children(primitive));
	}

	public function hydrate() {
		// @todo: We went through all this trouble making these things return errors,
		// we should actually handle them somewhere.
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

	public function new(root) {
		this.root = root;
		this.child = new ViewReconciler(this, root.adaptor);
	}

	public function currentNode():Node {
		throw root.child;
	}

	public function currentParent():Maybe<View> {
		return None;
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		return child.insert(root.child, cursor, hydrate);
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		return child.reconcile(root.child, cursor);
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

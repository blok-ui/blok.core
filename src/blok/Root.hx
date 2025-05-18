package blok;

import blok.core.*;
import blok.engine.*;

class Root<Primitive = Any> implements ViewHost implements Disposable {
	public final primitive:Primitive;
	public final adaptor:Adaptor;
	public final root:View;

	public var view(get, never):View;

	public function get_view():View {
		return root;
	}

	final child:Node;

	public function new(primitive, adaptor, child) {
		this.primitive = primitive;
		this.adaptor = adaptor;
		this.child = child;
		this.root = child.createView(None, adaptor);
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

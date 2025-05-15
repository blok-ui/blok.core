package blok;

import blok.core.*;
import blok.engine.*;

class Root<Primitive = Any> implements ViewHost implements Disposable {
	public final primitive:Primitive;
	public final adaptor:Adaptor;
	public final view:View;

	final child:Node;

	public function new(primitive, adaptor, child) {
		this.primitive = primitive;
		this.adaptor = adaptor;
		this.child = child;
		this.view = child.createView(None, adaptor);
	}

	public function mount() {
		// @todo: We went through all this trouble making these things return errors,
		// we should actually handle them somewhere.
		return view.insert(adaptor.children(primitive));
	}

	public function hydrate() {
		// @todo: We went through all this trouble making these things return errors,
		// we should actually handle them somewhere.
		return view.insert(adaptor.children(primitive), true);
	}

	public function getView():View {
		return view;
	}

	public function dispose() {
		view.remove(adaptor.children(primitive)).orThrow();
	}
}

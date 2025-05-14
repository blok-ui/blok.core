package blok;

import blok.engine.*;

class Root<Primitive = Any> implements ViewHost {
	final primitive:Primitive;
	final adaptor:Adaptor;
	final child:Node;
	final view:View;

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
}

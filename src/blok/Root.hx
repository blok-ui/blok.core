package blok;

import blok.core.*;
import blok.engine.*;

class Root<Primitive = Any> implements ViewHost implements Disposable {
	public static function from<Primitive>(view:IntoView):Root<Primitive> {
		return maybeFrom(view).orThrow();
	}

	public static function maybeFrom<Primitive>(view:IntoView):Maybe<Root<Primitive>> {
		return view
			.unwrap()
			.findAncestorOfType(RootView)
			.map(root -> root.getRootState());
	}

	public final primitive:Primitive;
	public final adaptor:Adaptor;

	final rootView:View;

	public function new(primitive, adaptor, child:Child) {
		this.primitive = primitive;
		this.adaptor = adaptor;
		this.rootView = new RootView(this, child);
	}

	public function mount() {
		return rootView.insert(adaptor.children(primitive));
	}

	public function hydrate() {
		return rootView.insert(adaptor.children(primitive), true);
	}

	public function getView():View {
		return rootView;
	}

	public function dispose() {
		rootView.remove(adaptor.children(primitive)).orThrow();
	}
}

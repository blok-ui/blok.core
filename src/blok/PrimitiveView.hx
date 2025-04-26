package blok;

import blok.debug.Debug;

abstract class PrimitiveView extends View {
	var primitive:Null<Dynamic> = null;

	public function getPrimitive() {
		return getOwnPrimitive();
	}

	public function getOwnPrimitive() {
		assert(primitive != null);
		return primitive;
	}
}

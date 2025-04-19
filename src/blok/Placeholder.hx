package blok;

import blok.debug.Debug;
import blok.engine.*;

using blok.engine.PrimitiveHostTools;

class Placeholder extends View implements PrimitiveHost {
	public static final componentType = new UniqueId();

	public static function node(?key):VNode {
		return new VComposableView(componentType, {}, Placeholder.new, key);
	}

	var primitive:Null<Dynamic> = null;

	public function new(node:VNode) {
		__node = node;
	}

	function __initialize() {
		var adaptor = getAdaptor();
		primitive = adaptor.createPlaceholderPrimitive();
		adaptor.insertPrimitive(primitive, __slot, () -> this.findNearestPrimitive());
	}

	function __hydrate(cursor:Cursor) {
		__initialize();
	}

	function __update() {}

	function __validate() {}

	function __dispose() {
		getAdaptor().removePrimitive(primitive, __slot);
	}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		getAdaptor().movePrimitive(getPrimitive(), oldSlot, newSlot, () -> this.findNearestPrimitive());
	}

	public function getPrimitive():Dynamic {
		assert(primitive != null);
		return primitive;
	}

	public function canBeUpdatedByNode(node:VNode):Bool {
		return node.type == componentType;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {}
}

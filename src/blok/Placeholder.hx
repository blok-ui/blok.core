package blok;

import blok.debug.Debug;

class Placeholder extends View {
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
		adaptor.insertPrimitive(this, primitive, __slot);
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
		getAdaptor().movePrimitive(this, getPrimitive(), oldSlot, newSlot);
	}

	public function getPrimitive():Dynamic {
		assert(primitive != null);
		return primitive;
	}

	public function getNearestPrimitive() {
		return getPrimitive();
	}

	public function canBeUpdatedByNode(node:VNode):Bool {
		return node.type == componentType;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {}
}

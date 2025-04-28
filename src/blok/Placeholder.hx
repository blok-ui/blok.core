package blok;

class Placeholder extends PrimitiveView {
	public static final componentType = new UniqueId();

	public static function node(?key):VNode {
		return new VComposableView(componentType, {}, Placeholder.new, key);
	}

	public function new(node:VNode) {
		__node = node;
	}

	function __initialize() {
		var adaptor = getAdaptor();
		primitive = adaptor.createPlaceholderPrimitive();
		adaptor.insertPrimitive(primitive, __slot);
	}

	function __hydrate(cursor:Cursor) {
		__initialize();
	}

	function __replace(other:View) {
		other.dispose();
		__initialize();
	}

	function __update() {}

	function __validate() {}

	function __dispose() {
		getAdaptor().removePrimitive(primitive, __slot);
	}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		getAdaptor().movePrimitive(getPrimitive(), oldSlot, newSlot);
	}

	public function getNearestPrimitive() {
		return getPrimitive();
	}

	public function canBeUpdatedByVNode(node:VNode):Bool {
		return node.type == componentType;
	}

	public function canReplaceOtherView(other:View):Bool {
		return false;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {}
}

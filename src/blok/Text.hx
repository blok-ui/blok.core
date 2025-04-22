package blok;

import blok.debug.Debug;
import blok.signal.Signal;

abstract Text(VNode) to VNode from VNode {
	@:from public static function ofString(value:String):Text {
		return TextView.node(value);
	}

	@:from public inline static function ofSignal(signal:ReadOnlySignal<String>):Text {
		return Scope.wrap(_ -> Text.node(signal.get()));
	}

	@:from public static function ofInt(number:Int) {
		return new Text(Std.string(number));
	}

	@:from public static function ofFloat(number:Float) {
		return new Text(Std.string(number));
	}

	public static function node(value:String):VNode {
		return new Text(value);
	}

	private function new(value, ?key) {
		this = TextView.node(value, key);
	}
}

class TextView extends View {
	public static final componentType = new UniqueId();

	public static function node(value:String, ?key:Key) {
		return new VComposableView(componentType, {value: value}, TextView.new, key);
	}

	var primitive:Null<Dynamic> = null;

	function new(node) {
		__node = node;
	}

	function __initialize() {
		var adaptor = getAdaptor();
		var props:{value:String} = __node.getProps();
		primitive = adaptor.createTextPrimitive(props.value);
		adaptor.insertPrimitive(this, primitive, __slot);
	}

	function __hydrate(cursor:Cursor) {
		primitive = cursor.current();
		assert(primitive != null, 'Hydration failed');
		cursor.next();
	}

	function __update() {
		var adaptor = getAdaptor();
		var props:{value:String} = __node.getProps();
		adaptor.updateTextPrimitive(primitive, props.value);
	}

	function __validate() {
		__update();
	}

	function __dispose() {
		getAdaptor().removePrimitive(primitive, __slot);
	}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		getAdaptor().movePrimitive(this, primitive, oldSlot, newSlot);
	}

	public function getNearestPrimitive() {
		return getPrimitive();
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

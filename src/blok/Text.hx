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

class TextView extends PrimitiveView {
	public static final viewType = new UniqueId();

	public static function node(content:String, ?key:Key):VNode {
		return new VText(content, key);
	}

	public function new(node:VText) {
		__node = node;
	}

	function __initialize() {
		var adaptor = getAdaptor();
		var props:{content:String} = __node.getProps();
		primitive = adaptor.createTextPrimitive(props.content);
		adaptor.insertPrimitive(primitive, __slot);
	}

	function __hydrate(cursor:Cursor) {
		primitive = cursor.current();
		assert(primitive != null, 'Hydration failed');
		cursor.next();
	}

	function __update() {
		var adaptor = getAdaptor();
		var props:{content:String} = __node.getProps();
		adaptor.updateTextPrimitive(primitive, props.content);
	}

	function __replace(other:View) {
		__initialize();
	}

	function __validate() {
		__update();
	}

	function __dispose() {
		getAdaptor().removePrimitive(primitive, __slot);
	}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		getAdaptor().movePrimitive(primitive, oldSlot, newSlot);
	}

	public function getNearestPrimitive() {
		return getPrimitive();
	}

	public function canBeUpdatedByVNode(node:VNode):Bool {
		return node.type == viewType;
	}

	public function canReplaceOtherView(other:View):Bool {
		return false;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {}
}

class VText implements VNode {
	public final type:UniqueId = TextView.viewType;
	public final key:Null<Key>;
	public final content:String;

	public function new(content, ?key) {
		this.content = content;
		this.key = key;
	}

	public function getProps<T:{}>():T {
		return cast {content: content};
	}

	public function createView():View {
		return new TextView(this);
	}
}

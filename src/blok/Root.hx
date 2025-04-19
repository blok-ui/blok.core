package blok;

import blok.engine.*;

class Root extends View implements PrimitiveHost {
	public static final componentType = new UniqueId();

	public static function node(props:{
		target:Dynamic,
		child:Child
	}) {
		return new VComponent(componentType, props, Root.new);
	}

	final target:Dynamic;
	final child:Child;

	var view:Null<View> = null;

	function new(node) {
		__node = node;
		(node.getProps() : {
			target: Dynamic,
			child: Child
		}).extract(try {
			target: target,
			child: child
		});
		this.target = target;
		this.child = child;
	}

	function __initialize() {
		view = child.createView();
		view.mount(getAdaptor(), this, createSlot(0, null));
	}

	function __hydrate(cursor:Cursor) {
		view = child.createView();
		view.hydrate(cursor.currentChildren(), getAdaptor(), this, createSlot(0, null));
		cursor.next();
	}

	function __update() {}

	function __validate() {}

	function __dispose() {}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		view.updateSlot(newSlot);
	}

	public function getPrimitive():Dynamic {
		return target;
	}

	public function canBeUpdatedByNode(node:VNode):Bool {
		return false;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		if (view != null) visitor(view);
	}
}

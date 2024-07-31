package blok.ui;

import blok.adaptor.*;
import blok.core.Owner;
import blok.signal.Runtime;

class Root extends View implements PrimitiveHost {
	public static final componentType = new UniqueId();

	public static function node(props:{
		target:Dynamic,
		child:() -> Child
	}) {
		return new VComponent(componentType, props, Root.new);
	}

	final target:Dynamic;
	final child:() -> Child;

	var component:Null<View> = null;

	function new(node) {
		__node = node;
		(node.getProps() : {
			target: Dynamic,
			child: () -> Child
		}).extract(try {
			target: target,
			child: child
		});
		this.target = target;
		this.child = child;
	}

	function render():Child {
		return Owner.with(this, () -> Runtime.current().untrack(child));
	}

	function __initialize() {
		component = render().createComponent();
		component.mount(getAdaptor(), this, createSlot(0, null));
	}

	function __hydrate(cursor:Cursor) {
		component = render().createComponent();
		component.hydrate(cursor.currentChildren(), getAdaptor(), this, createSlot(0, null));
		cursor.next();
	}

	function __update() {}

	function __validate() {}

	function __dispose() {}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		component.updateSlot(newSlot);
	}

	public function getPrimitive():Dynamic {
		return target;
	}

	public function canBeUpdatedByNode(node:VNode):Bool {
		return false;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		if (component != null) visitor(component);
	}
}

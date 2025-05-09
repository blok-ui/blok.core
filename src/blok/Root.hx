package blok;

class Root extends PrimitiveView {
	public static final componentType = new UniqueId();

	public static function node(props:{
		target:Dynamic,
		child:Child
	}) {
		return new VComposableView(componentType, props, Root.new);
	}

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
		this.primitive = target;
		this.child = child;
	}

	function __initialize() {
		view = child.createView();
		view.mount(getAdaptor(), this, new Slot(this, 0, null));
	}

	function __hydrate(cursor:Cursor) {
		view = child.createView();
		view.hydrate(cursor.currentChildren(), getAdaptor(), this, new Slot(this, 0, null));
		cursor.next();
	}

	function __replace(other:View) {
		__initialize();
	}

	function __update() {}

	function __validate() {}

	function __dispose() {}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		view.updateSlot(newSlot);
	}

	public function canBeUpdatedByVNode(node:VNode):Bool {
		return false;
	}

	public function canReplaceOtherView(other:View):Bool {
		return false;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		if (view != null) visitor(view);
	}
}

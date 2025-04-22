package blok;

import blok.debug.Debug;

typedef PortalProps = {
	public final target:Dynamic;
	public final child:Child;
}

class Portal extends View {
	public static final componentType = new UniqueId();

	@:fromMarkup
	@:noUsing
	@:noCompletion
	public static inline function fromMarkup(props:{
		public final target:Dynamic;
		@:children public final child:Child;
	}) {
		return wrap(props.target, props.child);
	};

	public inline static function wrap(target:Dynamic, child:Child, ?key) {
		return node({
			target: target,
			child: child
		}, key);
	}

	public static function node(props:PortalProps, ?key) {
		return new VComposableView(componentType, props, Portal.new, key);
	}

	var target:Null<Dynamic> = null;
	var child:Null<Child> = null;
	var marker:Null<View> = null;
	var root:Null<View> = null;

	function new(node) {
		__node = node;
		updateProps();
	}

	function setupPortalRoot() {
		root = Root.node({
			target: target,
			child: child
		}).createView();
	}

	function updateProps() {
		var props:PortalProps = __node.getProps();
		this.target = props.target;
		this.child = props.child;
	}

	function __initialize() {
		var adaptor = getAdaptor();

		marker = Placeholder.node().createView();
		marker.mount(adaptor, this, __slot);
		setupPortalRoot();
		root.mount(adaptor, this, null);
	}

	function __hydrate(cursor:Cursor) {
		var adaptor = getAdaptor();
		var cursor = adaptor.createCursor(target);

		marker = Placeholder.node().createView();
		marker.mount(adaptor, this, __slot);
		setupPortalRoot();
		root.hydrate(cursor, adaptor, this, null);
	}

	function __update() {
		updateProps();
		root.update(Root.node({
			target: target,
			child: child
		}));
	}

	function __validate() {
		root.validate();
	}

	function __dispose() {
		root?.dispose();
		root = null;
		marker?.dispose();
		marker = null;
	}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		marker?.updateSlot(newSlot);
	}

	public function getPrimitive():Dynamic {
		assert(marker != null);
		return marker.getPrimitive();
	}

	public function canBeUpdatedByNode(node:VNode):Bool {
		return node.type == componentType;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		root?.visitChildren(visitor);
	}
}

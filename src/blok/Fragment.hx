package blok;

import blok.debug.Debug.assert;

class Fragment extends View {
	public static final componentType = new UniqueId();

	@:fromMarkup
	@:noCompletion
	@:noUsing
	public static function fromMarkup(props:{
		@:children final children:Children;
	}) {
		return of(props.children);
	}

	public static function of(children:Children):Child {
		return new VComposableView(componentType, {children: children.toArray()}, Fragment.new);
	}

	@:deprecated('Use Fragment.of instead')
	public static function node(...children:Child):VNode {
		return new VComposableView(componentType, {children: children.toArray()}, Fragment.new);
	}

	var children:Array<View> = [];
	var marker:Null<View> = null;

	private function new(node) {
		__node = node;
	}

	function render() {
		var props:{children:Array<Child>} = __node.getProps();
		return props.children.filter(c -> c != null);
	}

	function createSlot(localIndex:Int, previous:Null<View>):Slot {
		assert(__slot?.host != null);
		return new FragmentSlot(__slot?.host, __slot?.index ?? 0, localIndex + 1, previous);
	}

	function __initialize() {
		var adaptor = getAdaptor();

		marker = Placeholder.node().createView();
		marker.mount(adaptor, this, __slot);

		var previous = marker;
		var nodes = render();
		var newChildren:Array<View> = [];

		for (i => node in nodes) {
			var child = node.createView();
			child.mount(adaptor, this, createSlot(i, previous));
			newChildren.push(child);
			previous = child;
		}

		this.children = newChildren;
	}

	function __hydrate(cursor:Cursor) {
		var adaptor = getAdaptor();

		marker = Placeholder.node().createView();
		marker.mount(adaptor, this, __slot);

		var previous = marker;
		var nodes = render();
		var newChildren:Array<View> = [];

		for (i => node in nodes) {
			var child = node.createView();
			child.hydrate(cursor, adaptor, this, createSlot(i, previous));
			newChildren.push(child);
			previous = child;
		}

		this.children = newChildren;
	}

	function __update() {
		children = Differ.diffChildren(getAdaptor(), this, children, render(), createSlot);
	}

	function __validate() {
		__update();
	}

	function __replace(other:View) {
		other.dispose();
		__initialize();
	}

	function __dispose() {
		marker?.dispose();
		marker = null;
	}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		if (marker != null) {
			marker.updateSlot(newSlot);
			var previous = marker;
			for (i => child in children) {
				child.updateSlot(createSlot(i, previous));
				previous = child;
			}
		}
	}

	public function getPrimitive():Dynamic {
		if (children.length == 0) {
			return marker?.getPrimitive();
		}
		return children[children.length - 1].getPrimitive();
	}

	public function canBeUpdatedByVNode(node:VNode):Bool {
		return node.type == componentType;
	}

	public function canReplaceOtherView(other:View):Bool {
		return false;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		for (child in children) if (!visitor(child)) return;
	}
}

class FragmentSlot extends Slot {
	public final localIndex:Int;

	public function new(view, index, localIndex, previous) {
		super(view, index, previous);
		this.localIndex = localIndex;
	}

	override function changed(other:Slot):Bool {
		if (index != other.index) {
			return true;
		}
		if (other is FragmentSlot) {
			var otherFragment:FragmentSlot = cast other;
			return localIndex != otherFragment.localIndex;
		}
		return false;
	}
}

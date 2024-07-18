package blok.ui;

import blok.diffing.Key;
import blok.adaptor.*;
import blok.diffing.Differ;

class Fragment extends View {
	public static final componentType = new UniqueId();

	public static function of(children:Children) {
		return new VFragment(componentType, children);
	}

	@:deprecated('Use Fragment.of instead')
	public static function node(...children:Child):VNode {
		return of(children.toArray());
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

	override function createSlot(localIndex:Int, previous:Null<View>):Slot {
		return new FragmentSlot(__slot?.index ?? 0, localIndex + 1, previous);
	}

	function __initialize() {
		var adaptor = getAdaptor();

		marker = Placeholder.node().createComponent();
		marker.mount(adaptor, this, __slot);

		var previous = marker;
		var nodes = render();
		var newChildren:Array<View> = [];

		for (i => node in nodes) {
			var child = node.createComponent();
			child.mount(adaptor, this, createSlot(i, previous));
			newChildren.push(child);
			previous = child;
		}

		this.children = newChildren;
	}

	function __hydrate(cursor:Cursor) {
		var adaptor = getAdaptor();

		marker = Placeholder.node().createComponent();
		marker.mount(adaptor, this, __slot);

		var previous = marker;
		var nodes = render();
		var newChildren:Array<View> = [];

		for (i => node in nodes) {
			var child = node.createComponent();
			child.hydrate(cursor, adaptor, this, createSlot(i, previous));
			newChildren.push(child);
			previous = child;
		}

		this.children = newChildren;
	}

	function __update() {
		children = diffChildren(this, children, render());
	}

	function __validate() {
		__update();
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

	public function canBeUpdatedByNode(node:VNode):Bool {
		return node.type == componentType;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		for (child in children) if (!visitor(child)) return;
	}
}

class FragmentSlot extends Slot {
	public final localIndex:Int;

	public function new(index, localIndex, previous) {
		super(index, previous);
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

@:access(blok.ui.Fragment)
class VFragment implements VNode {
	public final type:UniqueId;
	public final key:Null<Key>;

	final children:Array<VNode>;

	public function new(type, children, ?key) {
		this.type = type;
		this.children = children;
		this.key = key;
	}

	public function unwrap():Array<VNode> {
		return children;
	}

	public function getProps<T:{}>():T {
		return cast {children: children};
	}

	public function createComponent():View {
		return new Fragment(this);
	}
}

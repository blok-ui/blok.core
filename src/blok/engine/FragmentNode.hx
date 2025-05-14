package blok.engine;

class FragmentNode implements Node {
	public final key:Null<Key>;
	public final children:Array<Node>;

	public function new(children, ?key) {
		this.children = children;
		this.key = key;
	}

	public function withKey(key:Key) {
		return new FragmentNode(children, key);
	}

	public function matches(other:Node):Bool {
		return (other is FragmentNode) && key == other.key;
	}

	public function createView(parent:Maybe<View>, adaptor:Adaptor):View {
		return new FragmentView(parent, this, adaptor);
	}
}

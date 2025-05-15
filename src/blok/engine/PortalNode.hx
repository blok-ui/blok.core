package blok.engine;

class PortalNode implements Node {
	public final target:Any;
	public final child:Node;
	public final key:Null<Key>;

	public function new(target, child, ?key) {
		this.target = target;
		this.child = child;
		this.key = key;
	}

	public function matches(other:Node):Bool {
		return other is PortalNode && other.key == key;
	}

	public function createView(parent:Maybe<View>, adaptor:Adaptor):View {
		return new PortalView(parent, this, adaptor);
	}
}

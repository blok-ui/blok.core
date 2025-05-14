package blok.engine;

class ProviderNode<T:Providable> implements Node {
	public final key:Null<Key>;
	public final context:T;
	public final child:Node;
	public final shared:Bool;

	public function new(context, child, shared = false, ?key:Null<Key>) {
		this.context = context;
		this.child = child;
		this.shared = shared;
		this.key = key;
	}

	public function matches(other:Node):Bool {
		if (!(other is ProviderNode && other.key == key)) return false;

		var otherProvider:ProviderNode<Providable> = cast other;

		if (context.getContextId() != otherProvider.context.getContextId()) return false;

		return true;
	}

	public function createView(parent:Maybe<View>, adaptor:Adaptor):View {
		return new ProviderView(parent, this, adaptor);
	}
}

package blok.engine;

class ProviderNode<T:Providable> implements Node {
	public final key:Null<Key>;
	public final value:T;
	public final child:Node;
	public final shared:Bool;

	public function new(value, child, shared = false, ?key:Null<Key>) {
		this.value = value;
		this.child = child;
		this.shared = shared;
		this.key = key;
	}

	public function matches(other:Node):Bool {
		if (!(other is ProviderNode && other.key == key)) return false;

		// If a provider is being replaced with a new node and isn't shared, it MUST be
		// replaced, as all its children will need to be recomputed to ensure they have
		// access to the current value.
		//
		// For this reason you should:
		//
		// 1) Prefer shared providers.
		// 2) Place providers as high in the tree as possible.
		if (!shared) return false;

		var otherProvider:ProviderNode<Providable> = cast other;

		if (value.getContextId() != otherProvider.value.getContextId()) return false;

		return true;
	}

	public function createView(parent:Maybe<View>, adaptor:Adaptor):View {
		return new ProviderView(parent, this, adaptor);
	}
}

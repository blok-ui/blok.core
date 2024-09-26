package blok.ui;

import blok.diffing.Key;

class VComponent<Props:{}> implements VNode {
	public final type:UniqueId;
	public final key:Null<Key>;
	public final props:Props;
	public final factory:(node:VNode) -> View;

	public function new(type, props:Props, factory, ?key) {
		this.type = type;
		this.key = key;
		this.props = props;
		this.factory = factory;
	}

	public function getProps<T:{}>():T {
		return cast props;
	}

	public function createView():View {
		return factory(this);
	}
}

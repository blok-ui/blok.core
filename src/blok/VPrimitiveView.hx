package blok;

class VPrimitiveView implements VNode {
	public final type:UniqueId;
	public final key:Null<Key>;
	public final tag:String;
	public var props(default, null):{};
	public var children(default, null):Children;

	public function new(type, tag, props, ?children, ?key) {
		this.type = type;
		this.tag = tag;
		this.props = props;
		this.children = children ?? [];
		this.key = key;
	}

	public function getProps<T:{}>():T {
		return cast props;
	}

	public function createView():View {
		return new ElementPrimitiveView(this);
	}
}

package blok.engine;

@:forward
abstract PrimitiveNodeTag(String) to String {
	@:from public inline static function ofString(value:String):PrimitiveNodeTag {
		return new PrimitiveNodeTag(value);
	}

	public inline function new(name) {
		this = name;
	}
}

class PrimitiveNode<Attrs:{}> implements Node {
	public final tag:PrimitiveNodeTag;
	public final key:Null<Key>;
	public var attributes:Attrs;
	public var children:Maybe<Array<Node>>;

	public function new(tag:PrimitiveNodeTag, attributes, ?children, ?key) {
		this.tag = tag;
		this.attributes = attributes;
		this.children = children == null ? None : Some(children);
		this.key = key;
	}

	public function matches(other:Node):Bool {
		if (!(other is PrimitiveNode)) return false;

		var otherNode:PrimitiveNode<{}> = cast other;

		return otherNode.tag == tag && otherNode.key == key;
	}

	public function createView(parent:Maybe<View>, adaptor:Adaptor):View {
		return new PrimitiveView(parent, this, adaptor);
	}
}

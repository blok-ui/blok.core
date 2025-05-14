package blok.engine;

@:using(Node.NodeTools)
interface Node {
	public final key:Null<Key>;
	public function createView(parent:Maybe<View>, adaptor:Adaptor):View;
	public function matches(other:Node):Bool;
}

class NodeTools {
	public static function replaceWith<T:Node>(node:T, other:Node):Result<T, Node> {
		return if (node.matches(other)) Ok(cast other) else Error(other);
	}
}

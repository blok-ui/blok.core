package blok;

import blok.engine.*;

@:forward
abstract Placeholder(Node) to Node to Child {
	public static function node(?key:Key) {
		return if (key == null) {
			static var reusableNode:Null<Placeholder> = null;
			if (reusableNode == null) reusableNode = new Placeholder();
			return reusableNode;
		} else new Placeholder(key);
	}

	public inline function new(?key) {
		this = new TextNode('', key);
	}
}

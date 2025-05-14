package blok;

import blok.engine.*;

@:forward
abstract Placeholder(Node) to Node to Child {
	public inline static function node() {
		return new Placeholder();
	}

	public inline function new() {
		this = new TextNode('');
	}
}

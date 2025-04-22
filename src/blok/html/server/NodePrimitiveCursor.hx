package blok.html.server;

import blok.debug.Debug;

class NodePrimitiveCursor implements Cursor {
	var node:Null<NodePrimitive>;

	public function new(node) {
		this.node = node;
	}

	public function current():Null<Dynamic> {
		return node;
	}

	public function currentChildren():Cursor {
		if (node == null) return new NodePrimitiveCursor(null);
		return new NodePrimitiveCursor(node.children[0]);
	}

	public function next() {
		if (node == null) return;

		if (node.parent == null) {
			node = null;
			return;
		}

		assert(node != null);

		var parent = node.parent;
		var index = parent.children.indexOf(node);

		node = parent.children[index + 1];
	}

	public function move(current:Dynamic) {
		node = current;
	}

	public function clone() {
		return new NodePrimitiveCursor(node);
	}
}

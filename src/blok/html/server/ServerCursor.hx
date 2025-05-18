package blok.html.server;

import blok.engine.*;

class ServerCursor implements Cursor {
	var parent:NodePrimitive;
	var currentNode:Null<NodePrimitive>;

	public function new(parent, node) {
		this.parent = parent;
		this.currentNode = node;
	}

	public function next() {
		if (currentNode == null) return;

		if (currentNode.parent == null) {
			currentNode = null;
			return;
		}

		parent = currentNode.parent;

		var index = parent.children.indexOf(currentNode);
		currentNode = parent.children[index + 1];
	}

	public function current():Maybe<Any> {
		return currentNode.toMaybe();
	}

	public function insert(primitive:Any):Result<Any, Error> {
		var node:NodePrimitive = primitive;

		switch current() {
			case Some(previous):
				var index = parent.children.indexOf(previous);
				parent.insert(index + 1, node);
			case None:
				// Is parent.append safer?
				parent.insert(0, node);
		}

		this.currentNode = node;

		return Ok(node);
	}

	public function remove(primitive:Any):Result<Any, Error> {
		var toRemove:NodePrimitive = primitive;

		if (currentNode == toRemove) {
			var index = parent.children.indexOf(primitive);
			toRemove.remove();
			currentNode = parent.children[index];
			return Ok(toRemove);
		}

		toRemove.remove();
		return Ok(toRemove);
	}

	public function detach(primitive:Any):Result<Any, Error> {
		return remove(primitive);
	}
}

package blok.html.client;

import blok.engine.Cursor;
import js.html.*;

class ClientCursor implements Cursor {
	var parent:DOMElement;
	var currentNode:Null<Node>;

	public function new(parent, currentNode) {
		this.parent = parent;
		this.currentNode = currentNode;
	}

	public function current():Maybe<Any> {
		if (currentNode != null && currentNode.nodeType == Node.COMMENT_NODE) next();
		return currentNode.toMaybe();
	}

	public function next() {
		if (currentNode == null) return;
		currentNode = currentNode.nextSibling;
		if (currentNode != null && currentNode.nodeType == Node.COMMENT_NODE) next();
	}

	public function insert(primitive:Any):Result<Any, Error> {
		var element:DOMElement = primitive;

		switch current() {
			// Unsure about this:
			case Some(relative) if (relative == element):
				return Ok(element);
			case Some(relative):
				var relativeEl:DOMElement = relative;
				relativeEl.after(element);
			case None:
				parent.prepend(element);
		}

		currentNode = element;

		return Ok(element);
	}

	public function remove(primitive:Any):Result<Any, Error> {
		var toRemove:DOMElement = primitive;
		var sibling = toRemove?.nextSibling;

		toRemove?.remove();
		// Move cursor to the next node in line.
		currentNode = sibling;

		return Ok(toRemove);
	}

	public function detach(primitive:Any):Result<Any, Error> {
		return remove(primitive);
	}
}

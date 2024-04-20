package blok.html.server;

import blok.debug.Debug;

typedef NodePrimitiveToStringOptions = {
	public final ?includeTextMarkers:Bool;
}

abstract class NodePrimitive {
	public var parent:Null<NodePrimitive> = null;
	public var children:Array<NodePrimitive> = [];

	public function prepend(child:NodePrimitive) {
		assert(child != this);

		if (child.parent != null) child.remove();

		child.parent = this;
		children.unshift(child);
	}

	public function append(child:NodePrimitive) {
		assert(child != this);

		if (child.parent != null) child.remove();

		child.parent = this;
		children.push(child);
	}

	public function insert(pos:Int, child:NodePrimitive) {
		assert(child != this);

		if (child.parent != this && child.parent != null) child.remove();

		child.parent = this;

		if (!children.contains(child)) {
			children.insert(pos, child);
			return;
		}

		if (pos >= children.length) {
			pos = children.length;
		}

		var from = children.indexOf(child);

		if (pos == from) return;

		if (from < pos) {
			var i = from;
			while (i < pos) {
				children[i] = children[i + 1];
				i++;
			}
		} else {
			var i = from;
			while (i > pos) {
				children[i] = children[i - 1];
				i--;
			}
		}

		children[pos] = child;
	}

	public function remove() {
		if (parent != null) {
			parent.children.remove(this);
		}
		parent = null;
	}

	abstract public function toString(?options:NodePrimitiveToStringOptions):String;
}

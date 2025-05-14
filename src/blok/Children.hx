package blok;

import blok.engine.Node;

@:forward
abstract Children(Array<Node>) from Array<Child> from Array<Node> to Array<Node> {
	@:from public inline static function ofNode<T:Node>(child:T):Children {
		return [child];
	}

	@:from public inline static function ofNodes<T:Node>(children:Array<T>):Children {
		return (cast children : Array<Node>);
	}

	@:from public inline static function ofChild(child:Child):Children {
		return [child];
	}

	@:from public inline static function ofString(content:String):Children {
		return [Text.node(content)];
	}

	public inline function new(children) {
		this = children;
	}

	@:to public inline function toArray():Array<Child> {
		return this;
	}

	// @:to public inline function toChild():Child {
	// 	return Fragment.of(this);
	// }
}

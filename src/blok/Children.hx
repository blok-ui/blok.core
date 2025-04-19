package blok;

@:forward
abstract Children(Array<VNode>) from Array<Child> from Array<VNode> to Array<VNode> {
	@:from public inline static function ofVNode<T:VNode>(child:T):Children {
		return [child];
	}

	@:from public inline static function ofVNodes<T:VNode>(children:Array<T>):Children {
		return (cast children : Array<VNode>);
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

	@:to public inline function toChild():Child {
		return Fragment.of(this);
	}
}

package blok.ui;

@:forward
abstract Children(Array<Child>) from Array<Child> to Array<Child> {
  @:from public inline static function ofVNode(child:VNode):Children {
    return [ child ];
  }

  @:from public inline static function ofChild(child:Child):Children {
    return [ child ];
  }

  @:from public inline static function ofString(content:String):Children {
    return [ Text.node(content) ];
  }

  @:to public inline function toArray():Array<Child> {
    return this;
  }

  @:to public inline function toChild():Child {
    return Fragment.node(...this);
  }
}

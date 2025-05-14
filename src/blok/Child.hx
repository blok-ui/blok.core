package blok;

import blok.engine.Node;
import blok.signal.Computation;
import blok.signal.Signal;

@:forward
abstract Child(Node) from Text from Node to Node {
	@:from
	public inline static function ofArray(children:Array<Child>):Child {
		return Fragment.of(children);
	}

	@:from
	public inline static function ofComputationString(content:Computation<String>):Child {
		return Text.ofSignal(content);
	}

	@:from
	public inline static function ofReadonlySignalString(content:ReadOnlySignal<String>):Child {
		return Text.ofSignal(content);
	}

	@:from
	public inline static function ofSignalString(content:Signal<String>):Child {
		return Text.ofSignal(content);
	}

	@:from
	public inline static function ofComputationInt(content:Computation<Int>):Child {
		return Scope.wrap(_ -> Text.node(Std.string(content())));
	}

	@:from
	public inline static function ofReadonlySignalInt(content:ReadOnlySignal<Int>):Child {
		return Scope.wrap(_ -> Text.node(Std.string(content())));
	}

	@:from
	public inline static function ofSignalInt(content:Signal<Int>):Child {
		return Scope.wrap(_ -> Text.node(Std.string(content())));
	}

	@:from
	public inline static function ofComputationFloat(content:Computation<Float>):Child {
		return Scope.wrap(_ -> Text.node(Std.string(content())));
	}

	@:from
	public inline static function ofReadonlySignalFloat(content:ReadOnlySignal<Float>):Child {
		return Scope.wrap(_ -> Text.node(Std.string(content())));
	}

	@:from
	public inline static function ofSignalFloat(content:Signal<Float>):Child {
		return Scope.wrap(_ -> Text.node(Std.string(content())));
	}

	@:from
	public inline static function ofString(content:String):Child {
		return (content : Text);
	}

	@:from
	public inline static function ofInt(content:Int):Child {
		return (content : Text);
	}

	@:from
	public inline static function ofFloat(content:Float):Child {
		return (content : Text);
	}
}

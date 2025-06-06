package blok;

import blok.engine.*;
import blok.signal.Signal;

@:forward
abstract Text(Node) from Node to Node {
	@:from public inline static function ofString(value:String):Text {
		return new Text(value);
	}

	@:from public inline static function ofSignal(signal:ReadOnlySignal<String>):Text {
		return Scope.wrap(_ -> Text.node(signal.get()));
	}

	@:from public inline static function ofInt(number:Int) {
		return new Text(Std.string(number));
	}

	@:from public inline static function ofFloat(number:Float) {
		return new Text(Std.string(number));
	}

	public inline static function node(value:String):Node {
		return new Text(value);
	}

	private inline function new(value, ?key) {
		this = new TextNode(value, key);
	}
}

package blok.html.client;

import js.html.Node;
import js.Browser.*;

@:forward
abstract ClientRootPrimitive(Node) from Node to Node {
	@:from public inline static function ofSelector(selector:String):ClientRootPrimitive {
		return document.querySelector(selector);
	}
}

package blok.html.client;

import js.html.Node;
import js.Browser.*;

@:forward
abstract ClientRootNode(Node) from Node to Node {
	@:from public inline static function ofSelector(selector:String):ClientRootNode {
		return document.querySelector(selector);
	}
}

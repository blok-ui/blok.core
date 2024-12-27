package blok.html.server;

import blok.html.server.NodePrimitive;

using StringTools;

abstract ServerRootPrimitive(NodePrimitive) to NodePrimitive from NodePrimitive {
	// @todo: Make this more robust.
	@:from public static function ofSelector(selector:String):ServerRootPrimitive {
		return switch selector {
			case className if (className.startsWith('.')):
				return new ElementPrimitive('div', {className: className.substr(1)});
			case id if (id.startsWith('#')):
				return new ElementPrimitive('div', {id: id.substr(1)});
			case tag:
				return new ElementPrimitive(tag);
		}
	}
}

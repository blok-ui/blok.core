package blok.html.server;

import blok.html.server.NodePrimitive;

using StringTools;

class TextPrimitive extends NodePrimitive {
	var content:String;

	public function new(content) {
		this.content = content;
	}

	public function updateContent(content) {
		if (content == null) content = '';
		this.content = content;
	}

	public function toString(?options:NodePrimitiveToStringOptions):String {
		var includeMarker = options?.includeTextMarkers ?? true;
		return includeMarker ? '<!--#__BLOK_TEXT-->' + content.htmlEscape() : content;
	}
}

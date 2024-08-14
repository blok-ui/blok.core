package blok.html.server;

import blok.html.server.NodePrimitive;

using StringTools;

class TextPrimitive extends NodePrimitive {
	public static final marker = '<!--#__BLOK_TEXT-->';

	var content:String;

	public function new(content) {
		this.content = content;
	}

	public function updateContent(content) {
		if (content == null) content = '';
		this.content = content;
	}

	public function toString(?options:NodePrimitiveToStringOptions):String {
		options.extract({includeTextMarkers: includeMarker = true});
		var escaped = content.htmlEscape();
		return includeMarker ? marker + escaped : escaped;
	}
}

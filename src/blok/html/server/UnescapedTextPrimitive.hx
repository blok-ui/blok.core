package blok.html.server;

import blok.html.server.NodePrimitive;

// Note: this is currently not used by Blok itself, but there are places
// where outputting unescaped HTML is handy (such as when generating static HTML).
// We might add some sort of `dangerouslySetInnerHtml` feature later, which this
// can be used for.
class UnescapedTextPrimitive extends NodePrimitive {
	final content:String;

	public function new(content) {
		this.content = content;
	}

	public function toString(?options:NodePrimitiveToStringOptions):String {
		return content;
	}

	public function clone():NodePrimitive {
		return new UnescapedTextPrimitive(content);
	}
}

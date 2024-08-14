package blok.html.server;

class TextPrimitiveSuite extends Suite {
	@:test(expects = 2)
	function stringsEscapeCorrectly() {
		var text = new TextPrimitive('foo');
		text.toString().equals('${TextPrimitive.marker}foo');
		text.toString({includeTextMarkers: false}).equals('foo');
	}
}

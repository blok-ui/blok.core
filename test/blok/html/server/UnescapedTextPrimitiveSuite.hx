package blok.html.server;

class UnescapedTextPrimitiveSuite extends Suite {
	@:test(expects = 2)
	function outputsUnescapedHtmlAndOtherStrings() {
		var script = new ElementPrimitive('script');
		script.append(new UnescapedTextPrimitive('alert("this is fine")'));

		script.toString({includeTextMarkers: true}).equals('<script>alert("this is fine")</script>');

		var div = new ElementPrimitive('div');
		div.append(new UnescapedTextPrimitive('<span>this is fine</span>'));
		div.toString({includeTextMarkers: true}).equals('<div><span>this is fine</span></div>');
	}
}

package blok.html;

import blok.html.server.ElementPrimitive;

using TestTools;

class HtmlSuite extends Suite {
	@:test(expects = 1)
	function htmlViewParsesMarkupCorrectly() {
		return Html.view(<div className="foo">
			<p>"Foo"</p>
		</div>)
			.node()
			.renderAsync()
			.map(root -> {
				root.getPrimitive()
					.as(ElementPrimitive)
					.toString({includeTextMarkers: false})
					.equals('<div class="foo"><p>Foo</p></div>');
				Nothing;
			});
	}
}

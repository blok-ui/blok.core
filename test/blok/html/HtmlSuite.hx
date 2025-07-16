package blok.html;

class HtmlSuite extends Suite {
	@:test(expects = 1)
	function htmlViewParsesMarkupCorrectly() {
		return Html.view(<div className="foo">
			<p>"Foo"</p>
		</div>).renderAsync().then(root -> {
			root.primitive
				.toString({includeTextMarkers: false})
				.equals('<div class="foo"><p>Foo</p></div>');
			root.dispose();
			Task.nothing();
		});
	}
}

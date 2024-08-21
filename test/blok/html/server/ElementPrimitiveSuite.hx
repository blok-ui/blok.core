package blok.html.server;

class ElementPrimitiveSuite extends Suite {
	@:test(expects = 1)
	function attributesRenderCorrectly() {
		var div = new ElementPrimitive('div');
		div.setAttribute('id', 'foo');
		div.setAttribute('class', 'bar');
		div.toString().equals('<div id="foo" class="bar"></div>');
	}

	@:test(expects = 2)
	function classListWorks() {
		var div = new ElementPrimitive('div');
		div.setAttribute('class', 'foo');
		div.classList.add('bar');

		div.toString().equals('<div class="foo bar"></div>');

		div.classList.remove('bar');

		div.toString().equals('<div class="foo"></div>');
	}

	@:test(expects = 1)
	function voidElementsRenderCorrectly() {
		var input = new ElementPrimitive('input');
		input.setAttribute('name', 'hi');
		input.setAttribute('value', 'world');
		// @todo: I think self-closing tags are actually invalid HTML! Look into this.
		input.toString().equals('<input name="hi" value="world"/>');
	}

	@:test(expects = 1)
	function canGetChildNodes() {
		var div = new ElementPrimitive('div');
		div.append(new ElementPrimitive('div', {id: 'foo'}));
		div.append(new ElementPrimitive('div', {id: 'bar'}));

		div.find(el -> el.as(ElementPrimitive)?.getAttribute('id') == 'bar')
			.inspect(_ -> Assert.pass());
	}
}

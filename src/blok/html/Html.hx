package blok.html;

import blok.diffing.Key;
import blok.html.HtmlAttributes;

class Html {
	macro public static function view(expr);

	@:noCompletion
	static function element<T:{?key:Key}>(tag:String, ?attributes:T, ...children:Child):VHtmlPrimitive {
		return new VHtmlPrimitive(
			PrimitiveView.getTypeForTag(tag),
			tag,
			attributes ?? {},
			children,
			attributes?.key
		);
	}

	public inline static function html(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('html', attributes, ...children);
	}

	public inline static function body(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('body', attributes, ...children);
	}

	public inline static function iframe(?attributes:IFrameAttributes & HtmlEvents, ...children:Child) {
		return element('iframe', attributes, ...children);
	}

	public inline static function object(?attributes:ObjectAttributes & HtmlEvents, ...children:Child) {
		return element('object', attributes, ...children);
	}

	public inline static function head(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('head', attributes, ...children);
	}

	public inline static function title(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('title', attributes, ...children);
	}

	public inline static function div(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('div', attributes, ...children);
	}

	public inline static function code(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('code', attributes, ...children);
	}

	public inline static function aside(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('aside', attributes, ...children);
	}

	public inline static function article(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('article', attributes, ...children);
	}

	public inline static function blockquote(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('blockquote', attributes, ...children);
	}

	public inline static function section(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('section', attributes, ...children);
	}

	public inline static function header(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('header', attributes, ...children);
	}

	public inline static function footer(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('footer', attributes, ...children);
	}

	public inline static function main(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('main', attributes, ...children);
	}

	public inline static function nav(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('nav', attributes, ...children);
	}

	public inline static function table(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('table', attributes, ...children);
	}

	public inline static function thead(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('thead', attributes, ...children);
	}

	public inline static function tbody(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('tbody', attributes, ...children);
	}

	public inline static function tfoot(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('tfoot', attributes, ...children);
	}

	public inline static function tr(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('tr', attributes, ...children);
	}

	public inline static function td(?attributes:TableCellAttributes & HtmlEvents, ...children:Child) {
		return element('td', attributes, ...children);
	}

	public inline static function th(?attributes:TableCellAttributes & HtmlEvents, ...children:Child) {
		return element('th', attributes, ...children);
	}

	public inline static function h1(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h1', attributes, ...children);
	}

	public inline static function h2(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h2', attributes, ...children);
	}

	public inline static function h3(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h3', attributes, ...children);
	}

	public inline static function h4(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h4', attributes, ...children);
	}

	public inline static function h5(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h5', attributes, ...children);
	}

	public inline static function h6(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h6', attributes, ...children);
	}

	public inline static function strong(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('strong', attributes, ...children);
	}

	public inline static function em(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('em', attributes, ...children);
	}

	public inline static function span(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('span', attributes, ...children);
	}

	public inline static function a(?attributes:AnchorAttributes & HtmlEvents, ...children:Child) {
		return element('a', attributes, ...children);
	}

	public inline static function p(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('p', attributes, ...children);
	}

	public inline static function ins(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('ins', attributes, ...children);
	}

	public inline static function del(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('del', attributes, ...children);
	}

	public inline static function i(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('i', attributes, ...children);
	}

	public inline static function b(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('b', attributes, ...children);
	}

	public inline static function small(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('small', attributes, ...children);
	}

	public inline static function menu(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('menu', attributes, ...children);
	}

	public inline static function ul(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('ul', attributes, ...children);
	}

	public inline static function ol(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('ol', attributes, ...children);
	}

	public inline static function li(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('li', attributes, ...children);
	}

	public inline static function label(?attributes:LabelAttributes & HtmlEvents, ...children:Child) {
		return element('label', attributes, ...children);
	}

	public inline static function button(?attributes:ButtonAttributes & HtmlEvents, ...children:Child) {
		return element('button', attributes, ...children);
	}

	public inline static function pre(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('pre', attributes, ...children);
	}

	public inline static function picture(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('picture', attributes, ...children);
	}

	public inline static function canvas(?attributes:CanvasAttributes & HtmlEvents, ...children:Child) {
		return element('canvas', attributes, ...children);
	}

	public inline static function audio(?attributes:AudioAttributes & HtmlEvents, ...children:Child) {
		return element('audio', attributes, ...children);
	}

	public inline static function video(?attributes:VideoAttributes & HtmlEvents, ...children:Child) {
		return element('video', attributes, ...children);
	}

	public inline static function form(?attributes:FormAttributes & HtmlEvents, ...children:Child) {
		return element('form', attributes, ...children);
	}

	public inline static function fieldset(?attributes:FieldSetAttributes & HtmlEvents, ...children:Child) {
		return element('fieldset', attributes, ...children);
	}

	public inline static function legend(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('legend', attributes, ...children);
	}

	public inline static function select(?attributes:SelectAttributes & HtmlEvents, ...children:Child) {
		return element('select', attributes, ...children);
	}

	public inline static function option(?attributes:OptionAttributes & HtmlEvents, ...children:Child) {
		return element('option', attributes, ...children);
	}

	public inline static function dl(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('dl', attributes, ...children);
	}

	public inline static function dt(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('dt', attributes, ...children);
	}

	public inline static function dd(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('dd', attributes, ...children);
	}

	public inline static function details(?attributes:DetailsAttributes & HtmlEvents, ...children:Child) {
		return element('details', attributes, ...children);
	}

	public inline static function summary(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('summary', attributes, ...children);
	}

	public inline static function figure(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('figure', attributes, ...children);
	}

	public inline static function figcaption(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('figcaption', attributes, ...children);
	}

	public inline static function textarea(?attributes:TextAreaAttributes & HtmlEvents, ...children:Child) {
		return element('textarea', attributes, ...children);
	}

	public inline static function script(?attributes:ScriptAttributes & HtmlEvents, ...children:Child) {
		return element('script', attributes, ...children);
	}

	public inline static function style(?attributes:StyleAttributes & HtmlEvents, ...children:Child) {
		return element('style', attributes, ...children);
	}

	public inline static function br(?attributes:GlobalAttributes & HtmlEvents) {
		return element('br', attributes);
	}

	public inline static function embed(?attributes:EmbedAttributes & HtmlEvents & {?key:Key}) {
		return element('embed', attributes);
	}

	public inline static function hr(?attributes:GlobalAttributes & HtmlEvents) {
		return element('hr', attributes);
	}

	public inline static function img(?attributes:ImageAttributes & HtmlEvents) {
		return element('img', attributes);
	}

	public inline static function input(?attributes:InputAttributes & HtmlEvents) {
		return element('input', attributes);
	}

	public inline static function link(?attributes:LinkAttributes & HtmlEvents) {
		return element('link', attributes);
	}

	public inline static function meta(?attributes:MetaAttributes & HtmlEvents) {
		return element('meta', attributes);
	}

	public inline static function param(?attributes:ParamAttributes & HtmlEvents) {
		return element('param', attributes);
	}

	public inline static function source(?attributes:SourceAttributes & HtmlEvents) {
		return element('source', attributes);
	}

	public inline static function track(?attributes:TrackAttributes & HtmlEvents & {?key:Key}) {
		return element('track', attributes);
	}

	public inline static function wbr(?attributes:GlobalAttributes & HtmlEvents) {
		return element('wbr', attributes);
	}
}

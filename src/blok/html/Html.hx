package blok.html;

import blok.engine.*;
import blok.engine.PrimitiveNode;
import blok.html.HtmlAttributes;
import blok.html.HtmlEvents;
import blok.signal.Computation;
import blok.signal.Signal;

using Reflect;

class Html {
	@:skip
	macro public static function view(expr);

	@:skip
	public static function element<T:{?key:Key}>(tag:PrimitiveNodeTag, ?attributes:T, ...children:Child) {
		return new ElementNode(tag, attributes ?? {}, children);
	}

	public static function html(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('html', attributes, ...children);
	}

	public static function body(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('body', attributes, ...children);
	}

	public static function iframe(?attributes:IFrameAttributes & HtmlEvents, ...children:Child) {
		return element('iframe', attributes, ...children);
	}

	public static function object(?attributes:ObjectAttributes & HtmlEvents, ...children:Child) {
		return element('object', attributes, ...children);
	}

	public static function head(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('head', attributes, ...children);
	}

	public static function title(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('title', attributes, ...children);
	}

	public static function div(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('div', attributes, ...children);
	}

	public static function code(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('code', attributes, ...children);
	}

	public static function aside(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('aside', attributes, ...children);
	}

	public static function article(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('article', attributes, ...children);
	}

	public static function blockquote(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('blockquote', attributes, ...children);
	}

	public static function section(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('section', attributes, ...children);
	}

	public static function header(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('header', attributes, ...children);
	}

	public static function footer(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('footer', attributes, ...children);
	}

	public static function main(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('main', attributes, ...children);
	}

	public static function nav(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('nav', attributes, ...children);
	}

	public static function table(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('table', attributes, ...children);
	}

	public static function thead(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('thead', attributes, ...children);
	}

	public static function tbody(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('tbody', attributes, ...children);
	}

	public static function tfoot(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('tfoot', attributes, ...children);
	}

	public static function tr(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('tr', attributes, ...children);
	}

	public static function td(?attributes:TableCellAttributes & HtmlEvents, ...children:Child) {
		return element('td', attributes, ...children);
	}

	public static function th(?attributes:TableCellAttributes & HtmlEvents, ...children:Child) {
		return element('th', attributes, ...children);
	}

	public static function h1(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h1', attributes, ...children);
	}

	public static function h2(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h2', attributes, ...children);
	}

	public static function h3(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h3', attributes, ...children);
	}

	public static function h4(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h4', attributes, ...children);
	}

	public static function h5(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h5', attributes, ...children);
	}

	public static function h6(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('h6', attributes, ...children);
	}

	public static function strong(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('strong', attributes, ...children);
	}

	public static function em(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('em', attributes, ...children);
	}

	public static function span(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('span', attributes, ...children);
	}

	public static function a(?attributes:AnchorAttributes & HtmlEvents, ...children:Child) {
		return element('a', attributes, ...children);
	}

	public static function p(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('p', attributes, ...children);
	}

	public static function ins(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('ins', attributes, ...children);
	}

	public static function del(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('del', attributes, ...children);
	}

	public static function i(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('i', attributes, ...children);
	}

	public static function b(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('b', attributes, ...children);
	}

	public static function small(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('small', attributes, ...children);
	}

	public static function menu(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('menu', attributes, ...children);
	}

	public static function ul(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('ul', attributes, ...children);
	}

	public static function ol(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('ol', attributes, ...children);
	}

	public static function li(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('li', attributes, ...children);
	}

	public static function label(?attributes:LabelAttributes & HtmlEvents, ...children:Child) {
		return element('label', attributes, ...children);
	}

	public static function button(?attributes:ButtonAttributes & HtmlEvents, ...children:Child) {
		return element('button', attributes, ...children);
	}

	public static function pre(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('pre', attributes, ...children);
	}

	public static function picture(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('picture', attributes, ...children);
	}

	public static function canvas(?attributes:CanvasAttributes & HtmlEvents, ...children:Child) {
		return element('canvas', attributes, ...children);
	}

	public static function audio(?attributes:AudioAttributes & HtmlEvents, ...children:Child) {
		return element('audio', attributes, ...children);
	}

	public static function video(?attributes:VideoAttributes & HtmlEvents, ...children:Child) {
		return element('video', attributes, ...children);
	}

	public static function form(?attributes:FormAttributes & HtmlEvents, ...children:Child) {
		return element('form', attributes, ...children);
	}

	public static function fieldset(?attributes:FieldSetAttributes & HtmlEvents, ...children:Child) {
		return element('fieldset', attributes, ...children);
	}

	public static function legend(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('legend', attributes, ...children);
	}

	public static function select(?attributes:SelectAttributes & HtmlEvents, ...children:Child) {
		return element('select', attributes, ...children);
	}

	public static function option(?attributes:OptionAttributes & HtmlEvents, ...children:Child) {
		return element('option', attributes, ...children);
	}

	public static function dl(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('dl', attributes, ...children);
	}

	public static function dt(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('dt', attributes, ...children);
	}

	public static function dd(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('dd', attributes, ...children);
	}

	public static function details(?attributes:DetailsAttributes & HtmlEvents, ...children:Child) {
		return element('details', attributes, ...children);
	}

	public static function summary(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('summary', attributes, ...children);
	}

	public static function figure(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('figure', attributes, ...children);
	}

	public static function figcaption(?attributes:GlobalAttributes & HtmlEvents, ...children:Child) {
		return element('figcaption', attributes, ...children);
	}

	public static function textarea(?attributes:TextAreaAttributes & HtmlEvents, ...children:Child) {
		return element('textarea', attributes, ...children);
	}

	public static function script(?attributes:ScriptAttributes & HtmlEvents, ...children:Child) {
		return element('script', attributes, ...children);
	}

	public static function style(?attributes:StyleAttributes & HtmlEvents, ...children:Child) {
		return element('style', attributes, ...children);
	}

	public static function br(?attributes:GlobalAttributes & HtmlEvents) {
		return element('br', attributes);
	}

	public static function embed(?attributes:EmbedAttributes & HtmlEvents & {?key:Key}) {
		return element('embed', attributes);
	}

	public static function hr(?attributes:GlobalAttributes & HtmlEvents) {
		return element('hr', attributes);
	}

	public static function img(?attributes:ImageAttributes & HtmlEvents) {
		return element('img', attributes);
	}

	public static function input(?attributes:InputAttributes & HtmlEvents) {
		return element('input', attributes);
	}

	public static function link(?attributes:LinkAttributes & HtmlEvents) {
		return element('link', attributes);
	}

	public static function meta(?attributes:MetaAttributes & HtmlEvents) {
		return element('meta', attributes);
	}

	public static function param(?attributes:ParamAttributes & HtmlEvents) {
		return element('param', attributes);
	}

	public static function source(?attributes:SourceAttributes & HtmlEvents) {
		return element('source', attributes);
	}

	public static function track(?attributes:TrackAttributes & HtmlEvents & {?key:Key}) {
		return element('track', attributes);
	}

	public static function wbr(?attributes:GlobalAttributes & HtmlEvents) {
		return element('wbr', attributes);
	}
}

class ElementNode<Attrs:{}> extends PrimitiveNode<Attrs> {
	public function attr(name:AttributeName<GlobalAttributes>, value:ReadOnlySignal<String>) {
		if (name == 'class' && attributes.hasField('class')) {
			var prev:ReadOnlySignal<String> = attributes.field(name);
			attributes.setField(name, new Computation(() -> prev() + ' ' + value()));
			return this;
		}

		attributes.setField(name, value);
		return this;
	}

	public function on(event:AttributeName<HtmlEvents>, handler:ReadOnlySignal<EventListener>) {
		attributes.setField(event, handler);
		return this;
	}

	public function withKey(key:Key) {
		attributes.setField('key', key);
		return this;
	}

	public function child(...children:Child) {
		if (children.length == 0) return this;

		this.children = Some(switch this.children {
			case Some(old): old.concat(children);
			case None: children;
		});

		return this;
	}

	public function node():Child {
		return this;
	}
}

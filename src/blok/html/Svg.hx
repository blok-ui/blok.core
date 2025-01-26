package blok.html;

import blok.diffing.Key;
import blok.html.SvgAttributes;

class Svg {
	macro public static function view(expr);

	@:noCompletion
	static inline function element<T:{?key:Key}>(tag:String, attributes:T, ...children:Child) {
		return Html.element(tag, attributes, ...children);
	}

	public inline static function svg(attributes:SvgAttributes & HtmlEvents, ...children:Child) {
		return element('svg', attributes, ...children);
	}

	public inline static function g(attributes:BaseAttributes & HtmlEvents, ...children:Child) {
		return element('g', attributes, ...children);
	}

	public inline static function path(attributes:PathAttributes & HtmlEvents, ...children:Child) {
		return element('path', attributes, ...children);
	}

	public inline static function polygon(attributes:PolygonAttributes & HtmlEvents, ...children:Child) {
		return element('polygon', attributes, ...children);
	}

	public inline static function circle(attributes:CircleAttributes & HtmlEvents, ...children:Child) {
		return element('circle', attributes, ...children);
	}

	public inline static function rect(attributes:RectAttributes & HtmlEvents, ...children:Child) {
		return element('rect', attributes, ...children);
	}

	public inline static function ellipse(attributes:EllipseAttributes & HtmlEvents, ...children:Child) {
		return element('ellipse', attributes, ...children);
	}
}

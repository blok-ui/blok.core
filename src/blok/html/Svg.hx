package blok.html;

import blok.html.SvgAttributes;

class Svg {
	macro public static function view(expr);

	public inline static function svg(attributes:SvgAttributes & HtmlEvents, ...children:Child) {
		return Html.element('svg', attributes, ...children);
	}

	public inline static function g(attributes:BaseAttributes & HtmlEvents, ...children:Child) {
		return Html.element('g', attributes, ...children);
	}

	public inline static function path(attributes:PathAttributes & HtmlEvents, ...children:Child) {
		return Html.element('path', attributes, ...children);
	}

	public inline static function polygon(attributes:PolygonAttributes & HtmlEvents, ...children:Child) {
		return Html.element('polygon', attributes, ...children);
	}

	public inline static function circle(attributes:CircleAttributes & HtmlEvents, ...children:Child) {
		return Html.element('circle', attributes, ...children);
	}

	public inline static function rect(attributes:RectAttributes & HtmlEvents, ...children:Child) {
		return Html.element('rect', attributes, ...children);
	}

	public inline static function ellipse(attributes:EllipseAttributes & HtmlEvents, ...children:Child) {
		return Html.element('ellipse', attributes, ...children);
	}
}

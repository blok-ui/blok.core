package blok.html;

import blok.html.HtmlAttributes;
import blok.signal.Signal;

// Coppied from: https://github.com/haxetink/tink_svgspec
// svg attr reference: https://github.com/dumistoklus/svg-xsd-schema/blob/master/svg.xsd
typedef SvgAttributes = GlobalAttributes & {
	var ?width:ReadOnlySignal<String>;
	var ?height:ReadOnlySignal<String>;
	var ?viewBox:ReadOnlySignal<String>;
	var ?xmlns:ReadOnlySignal<String>; // Generally unused
}

typedef BaseAttributes = SvgAttributes & {
	var ?transform:ReadOnlySignal<String>;
}

typedef PathAttributes = BaseAttributes & {
	var ?d:ReadOnlySignal<String>;
	var ?pathLength:ReadOnlySignal<String>;
}

typedef PolygonAttributes = BaseAttributes & {
	var ?points:ReadOnlySignal<String>;
}

typedef RectAttributes = BaseAttributes & {
	var ?x:ReadOnlySignal<String>;
	var ?y:ReadOnlySignal<String>;
	var ?width:ReadOnlySignal<String>;
	var ?height:ReadOnlySignal<String>;
	var ?rx:ReadOnlySignal<String>;
	var ?ry:ReadOnlySignal<String>;
}

typedef CircleAttributes = BaseAttributes & {
	var ?cx:ReadOnlySignal<String>;
	var ?cy:ReadOnlySignal<String>;
	var ?r:ReadOnlySignal<String>;
}

typedef EllipseAttributes = BaseAttributes & {
	var ?cx:ReadOnlySignal<String>;
	var ?cy:ReadOnlySignal<String>;
	var ?rx:ReadOnlySignal<String>;
	var ?ry:ReadOnlySignal<String>;
}

typedef PresentationAttributes = Color & Containers & FeFlood & FillStroke & FilterPrimitives & FontSpecification & Gradients & Graphics & Images & LightingEffects & Markers & TextContentElements & TextElements & Viewports;

private typedef Color = {
	var ?color:ReadOnlySignal<String>;
	var ?colorInterpolation:ReadOnlySignal<String>;
}

private typedef Containers = {}
private typedef FeFlood = {}

private typedef FillStroke = {
	var ?fill:ReadOnlySignal<String>;
	var ?fillOpacity:ReadOnlySignal<String>;
	var ?fillRule:ReadOnlySignal<String>;
	var ?stroke:ReadOnlySignal<String>;
	var ?strokeDasharray:ReadOnlySignal<String>;
	var ?strokeDashoffset:ReadOnlySignal<String>;
	var ?strokeLinecap:ReadOnlySignal<String>;
	var ?strokeLinejoin:ReadOnlySignal<String>;
	var ?strokeMiterlimit:ReadOnlySignal<String>;
	var ?strokeOpacity:ReadOnlySignal<String>;
	var ?strokeWidth:ReadOnlySignal<String>;
}

private typedef FilterPrimitives = {}
private typedef FontSpecification = {}
private typedef Gradients = {}
private typedef Graphics = {}
private typedef Images = {}
private typedef LightingEffects = {}
private typedef Markers = {}
private typedef TextContentElements = {}
private typedef TextElements = {}
private typedef Viewports = {}

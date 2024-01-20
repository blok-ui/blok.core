package blok.html;

import blok.html.HtmlAttributes;
import blok.signal.Signal;

// Coppied from: https://github.com/haxetink/tink_svgspec
// svg attr reference: https://github.com/dumistoklus/svg-xsd-schema/blob/master/svg.xsd
typedef SvgAttributes = GlobalAttr & {
  @:optional var width:ReadOnlySignal<String>;
  @:optional var height:ReadOnlySignal<String>;
  @:optional var viewBox:ReadOnlySignal<String>;
  @:optional var xmlns:ReadOnlySignal<String>; // Generally unused
}

typedef BaseAttr = SvgAttributes & {
  @:optional var transform:ReadOnlySignal<String>;
}

typedef PathAttr = BaseAttr & {
  var d:ReadOnlySignal<String>;
  @:optional var pathLength:ReadOnlySignal<String>;
}

typedef PolygonAttr = BaseAttr & {
  var points:ReadOnlySignal<String>;
}

typedef RectAttr = BaseAttr & {
  @:optional var x:ReadOnlySignal<String>;
  @:optional var y:ReadOnlySignal<String>;
  var width:ReadOnlySignal<String>;
  var height:ReadOnlySignal<String>;
  @:optional var rx:ReadOnlySignal<String>;
  @:optional var ry:ReadOnlySignal<String>;
}

typedef CircleAttr = BaseAttr & {
  @:optional var cx:ReadOnlySignal<String>;
  @:optional var cy:ReadOnlySignal<String>;
  @:optional var r:ReadOnlySignal<String>;
}

typedef EllipseAttr = BaseAttr & {
  @:optional var cx:ReadOnlySignal<String>;
  @:optional var cy:ReadOnlySignal<String>;
  var rx:ReadOnlySignal<String>;
  var ry:ReadOnlySignal<String>;
}

typedef PresentationAttributes = Color & Containers & FeFlood & FillStroke & FilterPrimitives & FontSpecification & Gradients & Graphics & Images & LightingEffects & Markers & TextContentElements & TextElements & Viewports;

private typedef Color = {
  @:optional var color:ReadOnlySignal<String>;
  @:optional var colorInterpolation:ReadOnlySignal<String>;
}

private typedef Containers = {}
private typedef FeFlood = {}

private typedef FillStroke = {
  @:optional var fill:ReadOnlySignal<String>;
  @:optional var fillOpacity:ReadOnlySignal<String>;
  @:optional var fillRule:ReadOnlySignal<String>;
  @:optional var stroke:ReadOnlySignal<String>;
  @:optional var strokeDasharray:ReadOnlySignal<String>;
  @:optional var strokeDashoffset:ReadOnlySignal<String>;
  @:optional var strokeLinecap:ReadOnlySignal<String>;
  @:optional var strokeLinejoin:ReadOnlySignal<String>;
  @:optional var strokeMiterlimit:ReadOnlySignal<String>;
  @:optional var strokeOpacity:ReadOnlySignal<String>;
  @:optional var strokeWidth:ReadOnlySignal<String>;
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

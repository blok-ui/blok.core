package blok.html;

import blok.diffing.Key;
import blok.html.HtmlEvents;
import blok.html.SvgAttributes;
import blok.html.TagCollection;
import blok.ui.*;

class Svg {
  @:skip macro public static function view(expr);

  public static function svg(attributes:SvgAttributes & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('svg');
    return new VRealNode(type, 'svg', attributes, children.toArray(), attributes.key);
  }

  public static function g(attributes:BaseAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('g');
    return new VRealNode(type, 'g', attributes, children.toArray(), attributes.key);
  }

  public static function path(attributes:PathAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('path');
    return new VRealNode(type, 'path', attributes, children.toArray(), attributes.key);
  }

  public static function polygon(attributes:PolygonAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('polygon');
    return new VRealNode(type, 'polygon', attributes, children.toArray(), attributes.key);
  }

  public static function circle(attributes:CircleAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('circle');
    return new VRealNode(type, 'circle', attributes, children.toArray(), attributes.key);
  }

  public static function rect(attributes:RectAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('rect');
    return new VRealNode(type, 'rect', attributes, children.toArray(), attributes.key);
  }

  public static function ellipse(attributes:EllipseAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('ellipse');
    return new VRealNode(type, 'ellipse', attributes, children.toArray(), attributes.key);
  }
}

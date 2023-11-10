package blok.html;

import blok.diffing.Key;
import blok.html.HtmlAttributes;
import blok.html.HtmlEvents;
import blok.html.TagCollection;
import blok.ui.Child;
import blok.ui.VRealNode;

final class Html {
  @:skip macro public static function view(expr);

  public static function html(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('html');
    return new VRealNode(type, 'html', attributes, children.toArray(), attributes.key);
  }

  public static function body(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('body');
    return new VRealNode(type, 'body', attributes, children.toArray(), attributes.key);
  }

  public static function iframe(attributes:IFrameAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('iframe');
    return new VRealNode(type, 'iframe', attributes, children.toArray(), attributes.key);
  }

  public static function object(attributes:ObjectAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('object');
    return new VRealNode(type, 'object', attributes, children.toArray(), attributes.key);
  }

  public static function head(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('head');
    return new VRealNode(type, 'head', attributes, children.toArray(), attributes.key);
  }

  public static function title(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('title');
    return new VRealNode(type, 'title', attributes, children.toArray(), attributes.key);
  }

  public static function div(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('div');
    return new VRealNode(type, 'div', attributes, children.toArray(), attributes.key);
  }

  public static function code(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('code');
    return new VRealNode(type, 'code', attributes, children.toArray(), attributes.key);
  }

  public static function aside(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('aside');
    return new VRealNode(type, 'aside', attributes, children.toArray(), attributes.key);
  }

  public static function article(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('article');
    return new VRealNode(type, 'article', attributes, children.toArray(), attributes.key);
  }

  public static function blockquote(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('blockquote');
    return new VRealNode(type, 'blockquote', attributes, children.toArray(), attributes.key);
  }

  public static function section(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('section');
    return new VRealNode(type, 'section', attributes, children.toArray(), attributes.key);
  }

  public static function header(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('header');
    return new VRealNode(type, 'header', attributes, children.toArray(), attributes.key);
  }

  public static function footer(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('footer');
    return new VRealNode(type, 'footer', attributes, children.toArray(), attributes.key);
  }

  public static function main(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('main');
    return new VRealNode(type, 'main', attributes, children.toArray(), attributes.key);
  }

  public static function nav(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('nav');
    return new VRealNode(type, 'nav', attributes, children.toArray(), attributes.key);
  }

  public static function table(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('table');
    return new VRealNode(type, 'table', attributes, children.toArray(), attributes.key);
  }

  public static function thead(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('thead');
    return new VRealNode(type, 'thead', attributes, children.toArray(), attributes.key);
  }

  public static function tbody(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('tbody');
    return new VRealNode(type, 'tbody', attributes, children.toArray(), attributes.key);
  }

  public static function tfoot(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('tfoot');
    return new VRealNode(type, 'tfoot', attributes, children.toArray(), attributes.key);
  }

  public static function tr(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('tr');
    return new VRealNode(type, 'tr', attributes, children.toArray(), attributes.key);
  }

  public static function td(attributes:TableCellAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('td');
    return new VRealNode(type, 'td', attributes, children.toArray(), attributes.key);
  }

  public static function th(attributes:TableCellAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('th');
    return new VRealNode(type, 'th', attributes, children.toArray(), attributes.key);
  }

  public static function h1(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('h1');
    return new VRealNode(type, 'h1', attributes, children.toArray(), attributes.key);
  }

  public static function h2(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('h2');
    return new VRealNode(type, 'h2', attributes, children.toArray(), attributes.key);
  }

  public static function h3(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('h3');
    return new VRealNode(type, 'h3', attributes, children.toArray(), attributes.key);
  }

  public static function h4(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('h4');
    return new VRealNode(type, 'h4', attributes, children.toArray(), attributes.key);
  }

  public static function h5(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('h5');
    return new VRealNode(type, 'h5', attributes, children.toArray(), attributes.key);
  }

  public static function h6(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('h6');
    return new VRealNode(type, 'h6', attributes, children.toArray(), attributes.key);
  }

  public static function strong(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('strong');
    return new VRealNode(type, 'strong', attributes, children.toArray(), attributes.key);
  }

  public static function em(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('em');
    return new VRealNode(type, 'em', attributes, children.toArray(), attributes.key);
  }

  public static function span(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('span');
    return new VRealNode(type, 'span', attributes, children.toArray(), attributes.key);
  }

  public static function a(attributes:AnchorAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('a');
    return new VRealNode(type, 'a', attributes, children.toArray(), attributes.key);
  }

  public static function p(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('p');
    return new VRealNode(type, 'p', attributes, children.toArray(), attributes.key);
  }

  public static function ins(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('ins');
    return new VRealNode(type, 'ins', attributes, children.toArray(), attributes.key);
  }

  public static function del(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('del');
    return new VRealNode(type, 'del', attributes, children.toArray(), attributes.key);
  }

  public static function i(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('i');
    return new VRealNode(type, 'i', attributes, children.toArray(), attributes.key);
  }

  public static function b(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('b');
    return new VRealNode(type, 'b', attributes, children.toArray(), attributes.key);
  }

  public static function small(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('small');
    return new VRealNode(type, 'small', attributes, children.toArray(), attributes.key);
  }

  public static function menu(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('menu');
    return new VRealNode(type, 'menu', attributes, children.toArray(), attributes.key);
  }

  public static function ul(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('ul');
    return new VRealNode(type, 'ul', attributes, children.toArray(), attributes.key);
  }

  public static function ol(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('ol');
    return new VRealNode(type, 'ol', attributes, children.toArray(), attributes.key);
  }

  public static function li(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('li');
    return new VRealNode(type, 'li', attributes, children.toArray(), attributes.key);
  }

  public static function label(attributes:LabelAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('label');
    return new VRealNode(type, 'label', attributes, children.toArray(), attributes.key);
  }

  public static function button(attributes:ButtonAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('button');
    return new VRealNode(type, 'button', attributes, children.toArray(), attributes.key);
  }

  public static function pre(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('pre');
    return new VRealNode(type, 'pre', attributes, children.toArray(), attributes.key);
  }

  public static function picture(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('picture');
    return new VRealNode(type, 'picture', attributes, children.toArray(), attributes.key);
  }

  public static function canvas(attributes:CanvasAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('canvas');
    return new VRealNode(type, 'canvas', attributes, children.toArray(), attributes.key);
  }

  public static function audio(attributes:AudioAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('audio');
    return new VRealNode(type, 'audio', attributes, children.toArray(), attributes.key);
  }

  public static function video(attributes:VideoAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('video');
    return new VRealNode(type, 'video', attributes, children.toArray(), attributes.key);
  }

  public static function form(attributes:FormAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('form');
    return new VRealNode(type, 'form', attributes, children.toArray(), attributes.key);
  }

  public static function fieldset(attributes:FieldSetAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('fieldset');
    return new VRealNode(type, 'fieldset', attributes, children.toArray(), attributes.key);
  }

  public static function legend(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('legend');
    return new VRealNode(type, 'legend', attributes, children.toArray(), attributes.key);
  }

  public static function select(attributes:SelectAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('select');
    return new VRealNode(type, 'select', attributes, children.toArray(), attributes.key);
  }

  public static function option(attributes:OptionAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('option');
    return new VRealNode(type, 'option', attributes, children.toArray(), attributes.key);
  }

  public static function dl(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('dl');
    return new VRealNode(type, 'dl', attributes, children.toArray(), attributes.key);
  }

  public static function dt(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('dt');
    return new VRealNode(type, 'dt', attributes, children.toArray(), attributes.key);
  }

  public static function dd(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('dd');
    return new VRealNode(type, 'dd', attributes, children.toArray(), attributes.key);
  }

  public static function details(attributes:DetailsAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('details');
    return new VRealNode(type, 'details', attributes, children.toArray(), attributes.key);
  }

  public static function summary(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('summary');
    return new VRealNode(type, 'summary', attributes, children.toArray(), attributes.key);
  }

  public static function figure(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('figure');
    return new VRealNode(type, 'figure', attributes, children.toArray(), attributes.key);
  }

  public static function figcaption(attributes:GlobalAttr & HtmlEvents & { ?key:Key }, ...children:Child) {
    static final type = getTypeForTag('figcaption');
    return new VRealNode(type, 'figcaption', attributes, children.toArray(), attributes.key);
  }

  public static function textarea(attributes:TextAreaAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('textarea');
    return new VRealNode(type, 'textarea', attributes, null, key);
  }

  public static function script(attributes:ScriptAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('script');
    return new VRealNode(type, 'script', attributes, null, key);
  }

  public static function style(attributes:StyleAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('style');
    return new VRealNode(type, 'style', attributes, null, key);
  }

  public static function br(attributes:GlobalAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('br');
    return new VRealNode(type, 'br', attributes, null, key);
  }

  public static function embed(attributes:EmbedAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('embed');
    return new VRealNode(type, 'embed', attributes, null, key);
  }

  public static function hr(attributes:GlobalAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('hr');
    return new VRealNode(type, 'hr', attributes, null, key);
  }

  public static function img(attributes:ImageAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('img');
    return new VRealNode(type, 'img', attributes, null, key);
  }

  public static function input(attributes:InputAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('input');
    return new VRealNode(type, 'input', attributes, null, key);
  }

  public static function link(attributes:LinkAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('link');
    return new VRealNode(type, 'link', attributes, null, key);
  }

  public static function meta(attributes:MetaAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('meta');
    return new VRealNode(type, 'meta', attributes, null, key);
  }

  public static function param(attributes:ParamAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('param');
    return new VRealNode(type, 'param', attributes, null, key);
  }

  public static function source(attributes:SourceAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('source');
    return new VRealNode(type, 'source', attributes, null, key);
  }

  public static function track(attributes:TrackAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('track');
    return new VRealNode(type, 'track', attributes, null, key);
  }

  public static function wbr(attributes:GlobalAttr & HtmlEvents, ?key:Key) {
    static final type = getTypeForTag('wbr');
    return new VRealNode(type, 'wbr', attributes, null, key);
  }
}

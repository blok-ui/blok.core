package html;

import blok.VNode;

class Html {
  public static function text(text:String) {
    return new Text(text);
  }

  public static function fragment(...children:VNode) {
    return Fragment.node({ children: children.toArray() });
  }

  public static function div(props, ...children:VNode) {
    return new Element('div', props, null, children.toArray());
  }

  public static function h1(props, ...children:VNode) {
    return new Element('h1', props, null, children.toArray());
  }

  public static function button(props, ...children:VNode) {
    return new Element('button', props, null, children.toArray());
  }
}

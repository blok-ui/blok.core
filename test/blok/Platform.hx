package blok;

import js.html.Element;

@:access(blok.Component)
class Platform {
  public static function mount(el:Element, child:VNode) {
    var engine = new DomEngine();
    var root = new NativeComponent(cast el, { children: [ child ] });
    root.initializeRootComponent(engine);
    return root;
  }
}

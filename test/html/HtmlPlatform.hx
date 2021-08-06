package html;

import blok.PlatformWidget;
import blok.DefaultScheduler;
import blok.Platform;
import blok.VNode;
import blok.Component;
import blok.ConcreteManager;

class HtmlPlatform extends Platform {
  public static function mount(el:js.html.Element, vnode:VNode) {
    var platform = new HtmlPlatform(new DefaultScheduler());
    var root = new ElementWidget(el, Element.getElementType(el.tagName.toLowerCase()), {}, [vnode]);
    var pw = new PlatformWidget(root, platform);
    pw.mount();
    return pw;
  }

  public function createManagerForComponent(component:Component):ConcreteManager {
    return new ComponentManager(component);
  }
}

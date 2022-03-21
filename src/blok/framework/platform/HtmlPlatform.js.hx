package blok.framework.platform;

import blok.core.DefaultScheduler;

class HtmlPlatform extends Platform {
  public static function mount(
    el:js.html.Element,
    child:Widget
  ) {
    var platform = new HtmlPlatform(DefaultScheduler.getInstance());
    var root = new HtmlRootWidget(el, platform, child);
    var el = new HtmlRootElement(root);
    el.mount(null);
    return el;
  }

  public function insert(object:Dynamic, slot:Null<Slot>, findParent:()->Dynamic) {
    var el:js.html.Element = object;
    if (slot != null && slot.previous != null) {
      var relative:js.html.Element = slot.previous.getObject();
      relative.after(el);
    } else {
      var parent:js.html.Element = findParent();
      parent.appendChild(el);
    }
  }

  public function move(object:Dynamic, from:Null<Slot>, to:Null<Slot>) {
    var el:js.html.Element = object;

    if (from != null && to != null) {
      // If nothing is moving, avoid changing the DOM.
      // note: Didn't test this yet, may be fragile.
      if (from.index == to.index) return;
    }

    if (to != null && to.previous != null) {
      var relative:js.html.Element = to.previous.getObject();
      relative.after(el);
    } else {
      var parent:js.html.Element = el.parentElement;
      parent.appendChild(el);
    }
  }

  public function remove(object:Dynamic, slot:Null<Slot>) {
    var el:js.html.Element = object;
    el.remove();
  }
}

package helpers;

import blok.Component;
import js.Browser;
import blok.Platform;
import blok.VNode;

class TestContext {
  public final el:js.html.Element;
  final root:Component;

  public function new() {
    el = Browser.document.createElement('div');
    root = Platform.mount(el, None);
  }

  public function render(vn:VNode) {
    root.updateComponentProperties({ children: [ vn ] });
    root.patchRootComponent();
  }
}

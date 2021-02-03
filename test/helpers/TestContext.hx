package helpers;

import js.Browser;
import blok.Context;
import blok.Platform;
import blok.VNode;

class TestContext {
  public final el:js.html.Element;
  public final context:Context;
  
  public function new() {
    context = Platform.createContext();
    el = Browser.document.createElement('div');
  }

  public function render(vn:VNode) {
    Platform.patch(el, _ -> vn, context);
  }
}

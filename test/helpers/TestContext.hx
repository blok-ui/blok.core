package helpers;

import blok.VNode;
import blok.TestPlatform;
import blok.ChildrenComponent;

class TestContext {
  public final root:ChildrenComponent;

  public function new() {
    root = TestPlatform.mount(null);
  }

  public function render(vn:VNode) {
    root.updateComponentProperties({ children: [ vn ] });
    root.renderRootComponent();
  }
}

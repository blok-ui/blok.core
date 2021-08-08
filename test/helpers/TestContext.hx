package helpers;

import blok.FragmentWidget;
import blok.VNode;
import blok.TestPlatform;

class TestContext {
  public final root:FragmentWidget;

  public function new() {
    root = TestPlatform.mount();
  }

  public function render(vn:VNode, ?effect) {
    root.getPlatform().schedule(registerEffect -> {
      root.setChildren([ vn ]);
      root.performUpdate(registerEffect);
      if (effect != null) registerEffect(effect);
    });
  }
}

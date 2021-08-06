package helpers;

import blok.FragmentWidget;
import blok.PlatformWidget;
import blok.VNode;
import blok.TestPlatform;

class TestContext {
  public final platform:PlatformWidget;
  public final root:FragmentWidget;

  public function new() {
    platform = TestPlatform.mount();
    root = cast platform.root;
  }

  public function render(vn:VNode, ?effect) {
    platform.getPlatform().schedule(registerEffect -> {
      root.setChildren([ vn ]);
      root.performUpdate(registerEffect);
      if (effect != null) registerEffect(effect);
    });
  }
}

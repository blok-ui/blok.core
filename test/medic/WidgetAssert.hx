package medic;

import haxe.PosInfos;
import blok.ui.Widget;
import impl.TestingObject;
import impl.TestingPlatform;

class WidgetAssert {
  public inline static function mount(result:Widget, ?handler:(result:TestingObject)->Void) {
    TestingPlatform.mount(result, handler);
  }

  public static function renders(widget:Widget, expected:String, next:()->Void, ?p:PosInfos) {
    mount(widget, actual -> {
      Assert.equals(actual.toString(), expected, p);
      next();
    });
  }

  public static function renderWithoutAssert(widget:Widget) {
    TestingPlatform.mount(widget);
  }
}

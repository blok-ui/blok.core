package medic;

import haxe.PosInfos;
import blok.ui.VNode;
import impl.TestingPlatform;

class VNodeAssert {
  public inline static function mount(result:VNode, handler:(result:String)->Void) {
    TestingPlatform.mount(result, handler);
  }

  public static function renders(vn:VNode, expected:String, next:()->Void, ?p:PosInfos) {
    mount(vn, actual -> {
      Assert.equals(actual, expected, p);
      next();
    });
  }

  public static function renderWithoutAssert(vn:VNode) {
    TestingPlatform.mount(vn);
  }
}

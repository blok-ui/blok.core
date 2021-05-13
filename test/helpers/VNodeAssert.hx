package helpers;

import blok.ChildrenComponent;
import haxe.PosInfos;
import medic.Assert;
import blok.VNode;
import blok.TestPlatform;

class VNodeAssert {
  public static function mount(vn:VNode, handler:(result:String)->Void) {
    TestPlatform.mount(ChildrenComponent.node({
      children: [ vn ],
      ref: handler
    }));
  }

  public static function renders(vn:VNode, expected:String, next:()->Void, ?p:PosInfos) {
    mount(vn, actual -> {
      Assert.equals(actual, expected, p);
      next();
    });
  }

  public static function renderWithoutAssert(vn:VNode) {
    TestPlatform.mount(vn);
  }
}

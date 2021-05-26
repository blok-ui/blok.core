package helpers;

import blok.VNode;
import blok.ChildrenComponent;
import haxe.PosInfos;
import medic.Assert;
import blok.VNode;
import blok.TestPlatform;

class VNodeAssert {
  public static inline function toResult(vn:VNode):VNode {
    return vn;
  }

  public static function mount(result:VNode, handler:(result:String)->Void) {
    TestPlatform.mount(ChildrenComponent.node({
      children: [ result ],
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

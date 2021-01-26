package helpers;

import haxe.PosInfos;
import medic.Assert;
import blok.VNode;
import js.Browser;
import blok.Platform;

class VNodeAssert {
  public static function renders(vn:VNode, html:String, next:()->Void, ?p:PosInfos) {
    var node = Browser.document.createElement('div');
    Platform.mount(node, ctx -> Host.node({
      children: [ vn ],
      onComplete: () -> {
        Assert.equals(node.innerHTML, html, p);
        next();
      }
    }));
  }
}

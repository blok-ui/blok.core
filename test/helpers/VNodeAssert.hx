package helpers;

import js.Browser;
import js.html.Element;
import haxe.PosInfos;
import medic.Assert;
import blok.VNode;
import blok.Platform;

class VNodeAssert {
  public static function mount(vn:VNode, handler:(node:Element)->Void) {
    var node = Browser.document.createElement('div');
    Platform.mount(node, Host.node({
      children: [ vn ],
      onComplete: node -> handler(cast node)
    }));
    return node;
  }

  public static function renders(vn:VNode, html:String, next:()->Void, ?p:PosInfos) {
    mount(vn, node -> {
      innerHtmlEquals(node, html, p);
      next();
    });
  }

  public static function innerHtmlEquals(node:Element, html:String, ?p:PosInfos) {
    Assert.equals(node.innerHTML, html, p);
  }

  public static function renderWithoutAssert(vn:VNode) {
    var node = Browser.document.createElement('div');
    Platform.mount(node, vn);
  }
}

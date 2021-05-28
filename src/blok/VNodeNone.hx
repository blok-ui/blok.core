package blok;

import blok.VNodeType.noneType;

class VNodeNone implements VNode {
  public static final instance = new VNodeNone();

  public final type:VNodeType = noneType;
  public final key:Null<Key> = null;
  public final props:Dynamic = {};
  public final children:Null<Array<VNode>> = null;

  public function new() {}

  public function createComponent():Component {
    throw 'Invalid';
  }
  
  public function updateComponent(component:Component):Component {
    throw 'Invalid';
  }
}

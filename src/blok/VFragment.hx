package blok;

import blok.VNodeType.fragmentType;

class VFragment implements VNode {
  public final type:VNodeType = fragmentType;
  public final key:Null<Key>;
  public final props:Dynamic = {};
  public final children:Null<Array<VNode>> = null;

  public function new(children, ?key) {
    this.children = children;
    this.key = key;
  }

  public function createComponent():Component {
    throw 'Invalid';
  }

  public function updateComponent(component:Component):Component {
    throw 'Invalid';
  }
}

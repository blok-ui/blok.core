package blok;

import blok.VNodeType.fragmentType;

class VFragment implements VNode {
  static var emptyInst:Null<VFragment> = null;

  public static function empty():VNode {
    if (emptyInst == null) {
      emptyInst = new VFragment([]);
    }
    return emptyInst;
  }

  public final type:VNodeType = fragmentType;
  public final key:Null<Key>;
  public final props:Dynamic = {};
  public final children:Null<Array<VNode>> = null;

  public function new(children, ?key) {
    this.children = children;
    this.key = key;
  }

  public function createComponent(?parent:Component):Component {
    var component = new Fragment({ children: children });
    component.initializeComponent(parent, key);
    component.__getDiffer().diffChildren(component, component.render());
    return component;
  }

  public function updateComponent(component:Component):Component {
    component.updateComponentProperties({ children: children });
    component.__getDiffer().diffChildren(component, component.render());
    return component;
  }
}

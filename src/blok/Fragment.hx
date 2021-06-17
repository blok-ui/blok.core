package blok;

import blok.VNodeType.fragmentType;

@component(dontGenerateType)
class Fragment extends Component {
  public static function wrap(...children:VNode) {
    return new VFragment(children.toArray());
  }

  @prop public var children:Array<VNode>;

  public function new(props) {
    __initComponentProps(props);
  }

  public function getComponentType() {
    return fragmentType;
  }

  override function __ensureVNode(vn:Null<VNodeResult>):VNodeResult {
    return if (vn == null) new VNodeResult(VNone) else vn;
  }

  public function render() {
    return children;
  }
}

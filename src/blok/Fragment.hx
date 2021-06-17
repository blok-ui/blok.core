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

  public function render() {
    return children;
  }
}

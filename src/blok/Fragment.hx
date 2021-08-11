package blok;

class Fragment extends Component {
  public inline static function wrap(...children:VNode) {
    return node({ children: children.toArray() });
  }

  @prop public var children:Array<VNode>;

  public function render() {
    return children;
  }
}

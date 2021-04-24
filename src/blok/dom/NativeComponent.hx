package blok.dom;

import js.html.Node;

@:allow(blok.dom.NodeType)
@component(dontGenerateType)
class NativeComponent<Attrs> extends Component {
  @prop var attributes:Attrs = null;
  @prop var children:Array<VNode> = [];
  public final node:Node;
  final shouldUpdate:Bool;

  public function new(node, props, shouldUpdate = true) {
    this.node = node;
    this.shouldUpdate = shouldUpdate;
    __initComponentProps(props);
  }

  override function shouldComponentUpdate():Bool {
    return shouldUpdate;
  }

  public function render(context:Context):VNode {
    return if (children.length > 0) VFragment(children) else None;
  }
}

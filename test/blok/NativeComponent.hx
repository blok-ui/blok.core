package blok;

import js.html.Node;

@:allow(blok.NodeType)
@component(dontGenerateType)
class NativeComponent<Attrs> extends Component {
  @prop var attributes:Attrs = null;
  @prop var children:Array<VNode> = [];
  public final node:Node;
  final ref:Null<(node:Node)->Void>;
  final shouldUpdate:Bool;

  @effect
  function handleRef() {
    if (ref != null) ref(node);
  }

  public function new(node, props, ?ref, shouldUpdate = true) {
    this.node = node;
    this.ref = ref;
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

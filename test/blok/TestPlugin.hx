package blok;

class TestPlugin implements Plugin {
  public function new() {}

  public function prepareVNodes(component:Component, vnode:VNodeResult):VNodeResult {
    if (component is TextComponent) {
      return vnode;
    }
    return switch vnode.unwrap() {
      case VNone | VGroup([]): Text.text('');
      default: vnode;
    }
  }

  public function wasInitialized(component:Component) {
    // noop
  }

  public function wasRendered(component:Component) {
    // noop
  }

  public function willBeDisposed(component:Component) {
    // noop
  }
}

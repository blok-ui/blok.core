package blok;

class TestPlatform {
  public static function mount(child:VNode) {
    var root = new ChildrenComponent({ children: [ child ] });
    root.initializeRootComponent(new Engine([ new TestPlugin() ]));
    root.renderRootComponent();
    return root;
  }
}

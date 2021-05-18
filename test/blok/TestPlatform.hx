package blok;

class TestPlatform {
  public static function mount(child:VNode) {
    // var engine = new TestEngine();
    var root = new ChildrenComponent({
      children: [child]
    });
    // root.initializeRootComponent(engine);
    root.initializeRootComponent();
    return root;
  }
}

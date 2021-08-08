package blok;

class TestPlatform extends Platform {
  public static function mount(?child:VNode) {
    var children = child == null ? [] : [ child ];
    var platform = new TestPlatform(new DefaultScheduler());
    var root = new FragmentWidget(children);
    platform.mountRootWidget(root);
    return root;

    // var platform = new PlatformWidget(root, new TestPlatform(new DefaultScheduler()));
    // platform.mount();
    // return platform;
  }

  public function createManagerForComponent(component:Component):ConcreteManager {
    return new TestComponentManager(component);
  }
}

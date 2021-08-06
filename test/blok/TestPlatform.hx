package blok;

class TestPlatform extends Platform {
  public static function mount(?child:VNode) {
    var children = child == null ? [] : [ child ];
    var root = new FragmentWidget(children);
    var platform = new PlatformWidget(root, new TestPlatform(new DefaultScheduler()));
    platform.mount();
    return platform;
  }

  public function createManagerForComponent(component:Component):ConcreteManager {
    return new TestComponentManager(component);
  }
}

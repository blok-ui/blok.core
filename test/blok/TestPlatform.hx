package blok;

class TestPlatform {
  public static function mount(child:VNode) {
    var root = new ChildrenComponent({ children: [ child ] });
    root.initializeComponent();
    root.patchRootComponent();
    return root;
  }
}

package blok.ui;

abstract class RootWidget extends Widget {
  public final platform:Platform;
  public final child:Widget;

  public function new(platform, child) {
    super(null);
    this.platform = platform;
    this.child = child;
  }

  abstract public function resolveRootObject():Dynamic;
}

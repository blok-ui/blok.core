package blok.framework;

abstract class RootWidget extends Widget {
  public final platform:Platform;
  public final child:Widget;

  public function new(platform, child) {
    super(null);
    this.platform = platform;
    this.child = child;
  }
}

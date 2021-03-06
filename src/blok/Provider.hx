package blok;

final class Provider<T:ServiceProvider> extends Component {
  public inline static function provide<T:ServiceProvider>(service, build) {
    return node({
      service: service,
      build: build
    });
  }

  @prop var service:T;
  @prop var build:(context:Context)->VNode;
  @prop var teardown:(service:T)->Void = null;

  @dispose
  public function maybeTeardown() {
    if (teardown != null) teardown(service);
    __props.service = null;
  }

  override function __setContext(context:Context) {
    if (__context == null || __context.parent != context) {
      __context = context.getChild();
    }
    service.register(__context);
  }

  override function render(context):VNode {
    return build(context);
  }
}

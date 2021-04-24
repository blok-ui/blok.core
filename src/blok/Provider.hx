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

  override function __setEngine(engine:Engine) {
    __engine = engine.withNewContext();
    service.register(__engine.getContext());
  }

  public function render(context):VNode {
    return build(context);
  }
}


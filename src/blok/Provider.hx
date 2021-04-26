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
  @prop var teardown:Null<(service:T)->Void> = null;
  var context:Null<Context> = null;

  @dispose
  public function maybeTeardown() {
    if (teardown != null) teardown(service);
    __props.service = null;
  }

  @before
  public function setContext() {
    context = switch findInheritedComponentOfType(Provider) {
      case None: new Context();
      case Some(provider): provider.getContext().getChild();
    }
    service.register(context);
  }

  public function getContext() {
    return context;
  }

  public function render():VNode {
    return build(context);
  }
}

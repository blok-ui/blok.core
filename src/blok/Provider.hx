package blok;

final class Provider<T:ServiceProvider> extends Component {
  public inline static function provide<T:ServiceProvider>(service:T, build) {
    return node({
      service: service,
      build: build
    });
  }

  public inline static function factory() {
    return new ProviderFactory();
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
  public function findOrSyncContext() {
    context = switch findParentOfType(Provider) {
      case None: new Context();
      case Some(provider): provider.getContext().getChild();
    }
    service.register(context);
  }

  public function getContext() {
    return context;
  }

  public function render() {
    return build(context);
  }
}

private class ProviderFactory {
  final services:Array<ServiceProvider> = [];
  
  public function new() {}

  public function provide(provider:ServiceProvider) {
    services.push(provider);
    return this;
  }

  public function render(render:(context:Context)->VNode) {
    var first = services.shift();
    for (service in services) {
      var next = render;
      render = context -> Provider.provide(service, next);
    }
    return Provider.provide(first, render);
  }
}

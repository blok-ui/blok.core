package blok;

/**
  Provide a Service, making it accessable to all child widgets
  in the tree via the Context API.

  Note that any Disposable services registered here will be
  disposed when their Context is, meaning you SHOULD NOT use
  a Disposable ServiceProvider in more than one place.
**/
final class Provider<T:ServiceProvider> extends Component {
  /**
    Provide a Service that will become available from Context in the
    `build` method and in all child Widgets.

    Note: if you need to provide more than one service, use the
    `Provider.factory` or use `@provide` meta in a `blok.Service` or
    `blok.State`.
  **/
  public inline static function provide<T:ServiceProvider>(service:T, build) {
    return node({
      service: service,
      build: build
    });
  }

  /**
    A fluent API for providing several Services at once.
  **/
  public inline static function factory() {
    return new ProviderFactory();
  }

  @prop var service:T;
  @prop var build:(context:Context)->VNode;
  var context:Null<Context> = null;

  @init
  function findOrSyncContext() {
    context = switch findParentOfType(Provider) {
      case None: new Context();
      case Some(provider): provider.getContext().getChild();
    }
    addDisposable(context);
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

package blok.context;

import blok.ui.Component;
import blok.ui.VNode;

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
    `Provider.factory`, `@provide` meta in a `blok.Service` or
    `blok.State`, or a `blok.ServiceBundle(...)` (which `Provider.factory()`
    uses internally).
  **/
  public inline static function provide<T:ServiceProvider>(service:T, build) {
    return node({
      service: service,
      build: build
    });
  }

  /**
    Wrap a Context and provide its services.

    Note: be careful with this method! It will *not* inherit parent
    contexts, meaning that it should only be used at the root of an app
    *or* if you really know what you're doing.
  **/
  public inline static function forContext(parentContext:Context, build) {
    return node({
      parentContext: parentContext,
      build: build
    });
  }

  /**
    A fluent API for providing several Services at once.
  **/
  public inline static function factory() {
    return new ProviderFactory();
  }

  @prop var service:Null<T> = null;
  @prop var build:(context:Context)->VNode;
  @prop var parentContext:Null<Context> = null;
  var context:Null<Context> = null;

  @init
  function findOrCreateContext() {
    context = parentContext == null 
      ? switch findParentOfType(Provider) {
        case None: 
          new Context();
        case Some(provider): 
          provider.getContext().getChild();
      }
      : parentContext.getChild();

    addDisposable(context);
    if (service != null) service.register(context);
  }

  public function getContext() {
    return context;
  }

  public function render() {
    return build(context);
  }
}

private abstract ProviderFactory(ServiceBundle) from ServiceBundle {
  public inline function new() {
    this = new ServiceBundle([]);
  }

  public inline function provide(provider:ServiceProvider):ProviderFactory {
    this.addService(provider);
    return this;
  }

  public inline function render(build:(context:Context)->VNode) {
    return Provider.provide(this, build);
  }
}

package blok.components;

import blok.VNode;
import blok.Context;
import blok.Component;
import blok.core.Service;

final class Provider<T:Service> extends Component {
  public inline static function provide<T:Service>(service:T, build:(service:T)->VNode) {
    return node({
      service: service,
      build: build
    });
  }

  @prop var service:T;
  @prop var build:(service:T)->VNode;
  @prop var teardown:(service:T)->Void = null;

  @dispose
  public function maybeTeardown() {
    if (teardown != null) teardown(service);
    __props.service = null;
  }

  override function __setContext(context:Context) {
    if (__context == context) return;
    __context = context.getChild();
    service.register(__context);
  }

  override function render(context):VNode {
    return build(service);
  }
}

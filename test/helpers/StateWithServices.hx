package helpers;

import blok.Service;
import blok.State;

@service(fallback = new StateWithServices({
  fooService: FooService.DEFAULT
}))
class StateWithServices implements State {
  @provide var fooService:FooService;
}

@service(fallback = FooService.DEFAULT)
class FooService implements Service {
  public static final DEFAULT = new FooService('foo');

  public final foo:String;

  public function new(foo) {
    this.foo = foo;
  }
}

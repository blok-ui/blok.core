package helpers;

import blok.State;

@service(fallback = new SimpleState({ foo: 'foo' }))
class SimpleState implements State {
  @prop var foo:String;

  @update
  public function setFoo(foo) {
    return UpdateState({ foo: foo });
  }
}

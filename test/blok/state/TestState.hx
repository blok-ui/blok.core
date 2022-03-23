package blok.state;

import blok.context.Context;
import blok.context.Service;
import blok.context.Provider;
import medic.TestableComponent;
import impl.Node;

using Medic;
using medic.WidgetAssert;

class TestState implements TestCase {
  public function new() {}

  @:test('Registeres with context correctly')
  @:test.async
  public function testRegister(done) {
    SimpleState.provide({
      foo: 'Registered'
    }, context -> 
      Node.text(SimpleState.from(context).foo)
    ).renders('Registered', done);
  }

  @:test('Is disposed when its context is unounted')
  @:test.async
  public function testDispose(done) {
    var state = new SimpleState({
      foo: 'foo'
    });
    var ctx:Context = null;

    Provider.provide(state, context -> {
      ctx = context;
      Node.text(SimpleState.from(context).foo);
    }).renders('foo', () -> {
      ctx.dispose();
      state.isDisposed.isTrue();
      done();
    });
  }

  @:test('Static `use` is a shortcut')
  @:test.async
  public function testUse(done) {
    SimpleState.provide({
      foo: 'Registered'
    }, _ -> SimpleState.use(state -> Node.text(state.foo))
    ).renders('Registered', done);
  }

  @:test('States are observed')
  @:test.async
  public function testUpdates(done) {
    var state = new SimpleState({ foo: 'foo' });
    var tests = [
      (result:String) -> {
        result.equals('foo');
        state.setFoo('bar');
      },
      (result:String) -> {
        result.equals('bar');
        done();
      }
    ];
    Provider.node({
      service: state,
      build: context -> SimpleState.observe(context, state -> TestableComponent.node({
        children: [ Node.text(state.foo) ],
        test: (result) -> {
          var test = tests.shift();
          if (test != null) test(result.getObject().toString());
        }
      }))
    }).renderWithoutAssert();
  }

  @:test('`State.use` is a shortcut for observing the state')
  @:test.async
  public function testUseUpdates(done) {
    var state = new SimpleState({ foo: 'foo' });
    var tests = [
      (result:String) -> {
        result.equals('foo');
        state.setFoo('bar');
      },
      (result:String) -> {
        result.equals('bar');
        done();
      }
    ];
    Provider.node({
      service: state,
      build: _ -> SimpleState.use(state -> TestableComponent.node({
        children: [ Node.text(state.foo) ],
        test: (result) -> {
          var test = tests.shift();
          if (test != null) test(result.getObject().toString());
        }
      }))
    }).renderWithoutAssert();
  }

  @:test('States can provide services')
  @:test.async
  public function testStateWithServices(done) {
    var state = new StateWithServices({
      fooService: new FooService('Provided')
    });
    Provider.node({
      service: state,
      build: context -> Node.text(FooService.from(context).foo)
    }).renders('Provided', done);
  }
}

@service(fallback = new SimpleState({ foo: 'foo' }))
private class SimpleState implements State {
  @prop var foo:String;
  public var isDisposed:Bool = false;

  @update
  public function setFoo(foo) {
    return { foo: foo };
  }

  @dispose
  function markDisposed() {
    isDisposed = true;
  }
}

@service(fallback = FooService.DEFAULT)
private class FooService implements Service {
  public static final DEFAULT = new FooService('foo');

  public final foo:String;

  public function new(foo) {
    this.foo = foo;
  }
}

@service(fallback = new StateWithServices({
  fooService: FooService.DEFAULT
}))
private class StateWithServices implements State {
  @provide var fooService:FooService;
}

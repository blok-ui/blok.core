import blok.Provider;
import blok.Html;
import blok.State;
import blok.Service;
import helpers.Host;

using Medic;
using helpers.VNodeAssert;

class TestState implements TestCase {
  public function new() {}

  @:test('Registeres with context correctly')
  @:test.async
  public function testRegister(done) {
    SimpleState.provide({
      foo: 'Registered'
    }, context -> 
      Html.text(SimpleState.from(context).foo)
    ).renders('Registered', done);
  }

  @:test('Static `use` is a shortcut')
  @:test.async
  public function testUse(done) {
    SimpleState.provide({
      foo: 'Registered'
    }, _ -> SimpleState.use(state -> Html.text(state.foo))
    ).renders('Registered', done);
  }

  @:test('States are observed')
  @:test.async
  public function testUpdates(done) {
    var state = new SimpleState({ foo: 'foo' });
    var tests = [
      (node:js.html.Element) -> {
        node.innerHtmlEquals('foo');
        state.setFoo('bar');
      },
      (node:js.html.Element) -> {
        node.innerHtmlEquals('bar');
        done();
      }
    ];
    Provider.node({
      service: state,
      teardown: state -> state.dispose(),
      build: context -> SimpleState.observe(context, state -> Host.node({
        children: [ Html.text(state.foo) ],
        onComplete: (node) -> {
          var test = tests.shift();
          if (test != null) test(cast node);
        }
      }))
    }).renderWithoutAssert();
  }

  @:test('`State.use` is a shortcut for observing the state')
  @:test.async
  public function testUseUpdates(done) {
    var state = new SimpleState({ foo: 'foo' });
    var tests = [
      (node:js.html.Element) -> {
        node.innerHtmlEquals('foo');
        state.setFoo('bar');
      },
      (node:js.html.Element) -> {
        node.innerHtmlEquals('bar');
        done();
      }
    ];
    Provider.node({
      service: state,
      teardown: state -> state.dispose(),
      // Note: this is not optimal -- if we have access to `context` we
      //       should use it directly (`SimpleState.observe(context, ...)`)
      build: _ -> SimpleState.use(state -> Host.node({
        children: [ Html.text(state.foo) ],
        onComplete: (node) -> {
          var test = tests.shift();
          if (test != null) test(cast node);
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
      teardown: state -> state.dispose(),
      build: context -> Html.text(FooService.from(context).foo)
    }).renders('Provided', done);
  }
}

@service(fallback = new SimpleState({ foo: 'foo' }))
class SimpleState implements State {
  @prop var foo:String;

  @update
  public function setFoo(foo) {
    return UpdateState({ foo: foo });
  }
}

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

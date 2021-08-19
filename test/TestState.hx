import blok.ChildrenComponent;
import blok.Provider;
import blok.Text;
import blok.State;
import blok.Service;

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
      Text.text(SimpleState.from(context).foo)
    ).renders('Registered', done);
  }

  @:test('Is disposed when its context is unounted')
  @:test.async
  public function testDispose(done) {
    var state = new SimpleState({
      foo: 'foo'
    });
    var ctx:blok.Context = null;

    Provider.provide(state, context -> {
      ctx = context;
      Text.text(SimpleState.from(context).foo);
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
    }, _ -> SimpleState.use(state -> Text.text(state.foo))
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
      build: context -> SimpleState.observe(context, state -> ChildrenComponent.node({
        children: [ Text.text(state.foo) ],
        ref: (result) -> {
          var test = tests.shift();
          if (test != null) test(result);
        }
      }))
    }).toResult().renderWithoutAssert();
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
      // Note: this is not optimal -- if we have access to `context` we
      //       should use it directly (`SimpleState.observe(context, ...)`)
      build: _ -> SimpleState.use(state -> ChildrenComponent.node({
        children: [ Text.text(state.foo) ],
        ref: (result) -> {
          var test = tests.shift();
          if (test != null) test(result);
        }
      }))
    }).toResult().renderWithoutAssert();
  }

  @:test('States can provide services')
  @:test.async
  public function testStateWithServices(done) {
    var state = new StateWithServices({
      fooService: new FooService('Provided')
    });
    Provider.node({
      service: state,
      build: context -> Text.text(FooService.from(context).foo)
    }).toResult().renders('Provided', done);
  }
}

@service(fallback = new SimpleState({ foo: 'foo' }))
class SimpleState implements State {
  @prop var foo:String;
  public var isDisposed:Bool = false;

  @update
  public function setFoo(foo) {
    return UpdateState({ foo: foo });
  }

  @dispose
  function markDisposed() {
    isDisposed = true;
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

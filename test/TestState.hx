import blok.Provider;
import blok.Html;
import helpers.Host;
import helpers.SimpleState;

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
}

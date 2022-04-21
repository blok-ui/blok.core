package blok.provide;

import blok.ui.Component;
import impl.Node;

using Medic;
using medic.WidgetAssert;

class TestContext implements TestCase {
  public function new() {}

  @:test('Creates a shortcut to use Providers')
  @:test.async
  function testContextSimple(done) {
    Context
      .provide('foo', Context.use(context -> Node.text(context.get(String))))
      .renders('foo', done);
  }

  @:test('Works with classes')
  @:test.async
  function testClassWrapping(done) {
    Context
      .provide(new StringService('foo'), Context.use(context -> Node.text(context.get(StringService).value)))
      .renders('foo', done);
  }

  @:test('Context can use Elements to look up a service')
  @:test.async
  function testContextAware(done) {
    Context
      .provide('foo', ContextAwareComp.of({}))
      .renders('foo', done);
  }
}

class StringService {
  public final value:String;

  public function new(value) {
    this.value = value;
  }
}

class ContextAwareComp extends Component {
  function render() {
    var foo = Context.get(this, String);
    return Node.text(foo);
  }
}

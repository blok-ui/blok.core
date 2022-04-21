package blok.provide;

import impl.Node;

using Medic;
using medic.WidgetAssert;

class TestProvider implements TestCase {
  public function new() {}

  @:test('Providers push values down to their children')
  @:test.async
  function testProviderSimple(done) {
    StringProvider.of({
      value: 'foo',
      child: Context.use(context -> {
        var value = StringProvider.from(context);
        return Node.text(value);
      })
    }).renders('foo', done);
  }
}

typedef StringProvider = Provider<String>;

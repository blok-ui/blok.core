import blok.Context;

using Medic;

class TestContext implements TestCase {
  public function new() {}

  @:test('Context works with ServiceProvider')
  function testServiceProvider() {
    var context = new Context();
    context.addService({ 
      register: context -> context.set('foo', 'foo')
    });
    (context.get('foo'):String).equals('foo');
  }

  @:test('Context works with ServiceResolver')
  function testServiceResolver() {
    var context = new Context();
    context.getService({ 
      from: function (_):String return 'foo'
    }).equals('foo');
  }

  @:test('Context will check its parent for data')
  function testChild() {
    var context = new Context();
    var child = context.getChild();
    
    context.set('foo', 'foo');
    child.set('bar', 'bar');
    
    (child.get('foo'):String).equals('foo');
    (context.get('bar'):String).equals(null);
    (child.get('bar'):String).equals('bar');
  }
}

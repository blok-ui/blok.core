import blok.Record;

using Medic;

class TestRecord implements TestCase {
  public function new() {}
  
  @:test('Records with the same props equal each other')
  function testEqual() {
    var a = new Foo({ foo: 'foo' });
    var b = new Foo({ foo: 'foo' });
    // (a == b).isTrue(); // One day :/
    a.equals(b).isTrue();
  }

  @:test('Records with different props don\'t equal each other')
  function testNotEqual() {
    var a = new Foo({ foo: 'foo' });
    var b = new Foo({ foo: 'bar' });
    a.equals(b).isFalse();
  }
}

class Foo implements Record {
  @prop var foo:String;
}

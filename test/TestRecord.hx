import haxe.Json;
import blok.Record;

using Medic;
using Reflect;
using Type;

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

  @:test('"with" methods are generated for each field')
  function testWithFields() {
    var a = new Foo({ foo: 'foo' });
    a.withFoo('bar').foo.equals('bar');
  }

  @:test('"toJson" works')
  function testToJson() {
    var bar = new Bar({
      bar: 'bar',
      foo: new Foo({ foo: 'foo' })
    });
    var data:{} = bar.toJson();
    (data.field('bar'):String).equals('bar');
    (data.field('foo'):{ foo:String }).foo.equals('foo');
  }

  @:test('"fromJson" works')
  function testFromJson() {
    var bar = Bar.fromJson({
      bar: 'bar',
      foo: { foo: 'foo' }
    });
    bar.bar.equals('bar');
    bar.foo.hashCode().equals(new Foo({ foo: 'foo' }).hashCode());
  }

  @:test('Dates are first-class')
  function testDates() {
    var date = Date.now();
    var record = new WithDate({ date: date });
    (record.toJson().field('date'):String).equals(date.toString());
    var fromJson = WithDate.fromJson(record.toJson());
    fromJson.date.getDate().equals(date.getDate());
  }

  @:test('Json serialization works')
  function testJson() {
    var data = WithSerializeable.fromJson({
      json: [ 
        {
          __foo__: 'foo'
        }, 
        {
          __foo__: 'bar'
        }
      ]
    });
    data.json.length.equals(2);
    var json = data.json[0];
    json.getClass().getClassName().equals(JsonTester.getClassName());
    json.foobar().equals('foo bar');
    Json.stringify(data.toJson()).equals(Json.stringify({
      json: [ 
        {
          __foo__: 'foo'
        }, 
        {
          __foo__: 'bar'
        }
      ]
    }));
  }

  @:test('Records can have themseleves as children')
  function testRecursive() {
    // Note: this is mostly testing to ensure that the macro builder
    //       compiles.
    var data = new IsRecursive({
      foo: 'bar',
      children: [
        new IsRecursive({ foo: 'bin' })
      ]
    });
    data.children.length.equals(1);
    Json.stringify(data.toJson()).equals(Json.stringify({
      foo: 'bar',
      children: [
        { foo: 'bin', children: [] }
      ]
    }));
  }
}

class Foo implements Record {
  @prop var foo:String;
}

class Bar implements Record {
  @prop var bar:String;
  @prop var foo:Foo;
}

class WithDate implements Record {
  @prop var date:Date;
}

class WithSerializeable implements Record {
  @prop var json:Array<JsonTester>;
}

class IsRecursive implements Record {
  @prop var foo:String;
  @prop var children:Array<IsRecursive> = [];
}

class JsonTester {
  public static function fromJson(data:Dynamic) {
    return new JsonTester(Reflect.field(data, '__foo__'));
  }

  final foo:String;

  public function new(foo) {
    this.foo = foo;
  }

  public function foobar() {
    return foo + ' bar';
  }

  public function toJson():Dynamic {
    return { __foo__: foo };
  }
}

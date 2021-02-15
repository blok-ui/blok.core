import blok.Observable;

using Medic;

class TestObservable implements TestCase {
  public function new() {}

  @:test('Simple observation')
  public function testSimple() {
    var obs = new Observable('foo');
    var expected = 'foo';
    
    obs.observe(value -> value.equals(expected));
    expected = 'bar';
    obs.update('bar');
  }

  @:test('Observable can be disposed')
  public function testDispose() {
    var obs = new Observable(0);
    var times = 0;

    obs.observe(value -> value.equals(times));
    times++;
    obs.update(1);
    times++;
    obs.update(2);
    obs.dispose();
    obs.update(3);
  }

  @:test('Observable returns an Observer that can be disposed')
  public function testObserverDispose() {
    var obs = new Observable(0);
    var times = 0;
    var link = obs.observe(value -> value.equals(times));

    times++;
    obs.update(1);
    times++;
    obs.update(2);
    link.dispose();
    obs.update(3);
  }

  @:test('Observables can be mapped')
  function testMap() {
    var obs = new Observable('foo');
    var expected = 'foo:bar';
    var mapped = obs.map(value -> value + ':bar');
    
    mapped.observe(value -> value.equals(expected));

    expected = 'bar:bar';
    obs.update('bar');
    mapped.dispose();
    obs.update('some value');
  }
}

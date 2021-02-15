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

  @:test('Many functions can be notified')
  public function testNotfy() {
    var obs = new Observable('foo');
    var out:String = '';
    
    obs.observe(value -> out += value + '1');
    var link = obs.observe(value -> out += value + '2');
    obs.observe(value -> out += value + '3');

    out = '';

    obs.update('foo');
    out.equals(''); // No update if values are the same.

    obs.notify(); // force notification.
    out.equals('foo3foo2foo1');
    
    out = '';
    obs.update('bar');
    out.equals('bar3bar2bar1');

    out = '';
    link.dispose();
    obs.notify();
    out.equals('bar3bar1'); // Second observer should be disposed.
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
    
    // Should have one mapped observer:
    obs.length.equals(1);
    
    mapped.observe(value -> value.equals(expected));

    expected = 'bar:bar';
    obs.update('bar'); // Should notify mapped observer
    
    mapped.dispose();
    obs.update('some value'); // Should not notify anything

    // Removing a mapped observable should remove its linked observer
    // as well:
    obs.length.equals(0);
  }
}

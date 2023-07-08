import blok.ui.*;

function main() {
  trace(Test.node({ foo: 'foo' }));
  trace(Placeholder.node());
}

class Test extends AutoComponent {
  @:constant final bar:String = 'bar';
  @:signal final foo:String;
  @:observable final bin:String = 'bin';
  @:computed final fooBar:String = foo() + bar + bin();

  function render() {
    return Fragment.node(
      foo,
      bin,
      fooBar
    );
  }
}

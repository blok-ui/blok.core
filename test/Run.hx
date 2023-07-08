import js.Browser;
import blok.html.client.Client.mount;
import blok.html.Html;
import blok.ui.*;

function main() {
  mount(Browser.document.getElementById('root'), Test.node({
    foo: 'foo'
  }));
}

class Test extends ObserverComponent {
  @:constant final bar:String = 'bar';
  @:signal final foo:String;
  @:observable final bin:String = 'bin';
  @:computed final fooBar:String = foo() + bar + bin();

  function render() {
    return Html.div({
      className: 'Test!',
      onClick: _ -> trace('test')
    },
      bar, foo, fooBar
    );
  }
}

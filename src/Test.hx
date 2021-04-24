import blok.Provider;
import blok.State;
import js.Browser;
import blok.Context;
import blok.Component;
import blok.dom.Html;
import blok.dom.Platform;

function main() {
  Platform.mount(
    Browser.document.getElementById('root'),
    Provider.provide(new Foo({ foo: 'bar' }), ctx -> 
      Html.div({}, [ 
        Html.text('foo'),
        TestComp.node({ foo: 'not foo' }) 
      ])
    )
  );
}

@lazy
class TestComp extends Component {
  @prop var foo:String;
  @use var fooState:Foo;

  @update
  function setFoo(foo:String) {
    return UpdateState({ foo: foo });
  }

  @effect
  function testEffect() {
    trace('foo');
  }

  public function render(context:Context) {
    return Html.div({
      className: 'foo'
    }, [ 
      Html.text(foo + ' ' + fooState.foo),
      Html.button({
        onclick: e -> setFoo('bar')
      }, [ Html.text('Make bar') ])
    ]);
  }
}

@service(fallback = new Foo({ foo: 'foo' }))
class Foo implements State {
  @prop var foo:String;
}

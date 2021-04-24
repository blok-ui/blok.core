import js.Browser;
import blok.Component;
import blok.dom.Html;
import blok.dom.Platform;

function main() {
  Platform.mount(
    Browser.document.getElementById('root'),
    Html.div({}, [ 
      Html.text('foo'),
      TestComp.node({ foo: 'not foo' }) 
    ])
  );
}

@lazy
class TestComp extends Component {
  @prop var foo:String;

  @update
  function setFoo(foo:String) {
    return UpdateState({ foo: foo });
  }

  @effect
  function testEffect() {
    trace('foo');
  }

  public function render() {
    return Html.div({
      className: 'foo'
    }, [ 
      Html.text(foo),
      Html.button({
        onclick: e -> setFoo('bar')
      }, [ Html.text('Make bar') ])
    ]);
  }
}

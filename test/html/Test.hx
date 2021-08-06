package html;

import blok.Component;
import js.Browser;

function main() {
  HtmlPlatform.mount(
    Browser.document.getElementById('root'),
    Html.fragment(
      Html.div({}, Html.text('Hello world!')),
      Html.div({}, Html.text('How are'), Html.text(' things.')),
      Example.node({ foo: 'foo', bar: 'bar' })
    )
  );
}

class Example extends Component {
  @prop var foo:String;
  @prop var bar:String;
  @prop var foos:Array<String> = [ 'one' ];

  @update
  public function setFooAndBar(foo, bar) {
    return UpdateState({
      foo: foo,
      bar: bar
    });
  }

  @update
  public function addFoo(foo) {
    return UpdateState({
      foos: foos.concat([ foo ])
    });
  }

  @update
  public function removeFoo(index:Int) {
    var filtered = foos.copy();
    filtered.splice(index, 1);
    return UpdateState({
      foos: filtered
    });
  }

  @effect
  function testEffect() {
    trace('Rendered!');
  }

  function render() {
    return [
      Html.div({},
        Html.text(foo),
        Html.text(' and '),
        Html.text(bar)
      ),
      Html.button({
        onclick: e -> setFooAndBar('bin', 'bax')
      }, Html.text('test')),
      Html.fragment(...[ for (index => foo in foos) 
        Html.div({}, Html.text(foo), Html.button({
          onclick: _ -> removeFoo(index)
        }, Html.text('x')))
      ]),
      Html.button({
        onclick: e -> addFoo('foo')
      }, Html.text('Add'))
    ];
  }
}

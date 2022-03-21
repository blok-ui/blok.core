import js.Browser;
import blok.framework.platform.HtmlPlatform;
import blok.framework.platform.Html;
import blok.framework.Component;
import blok.framework.Widget;
import blok.framework.context.Service;

function main() {
  HtmlPlatform.mount(
    Browser.document.getElementById('root'),
    Layout.node({ children: [
      Html.text('Foo'),
      NumberGoUp.node({ number: 0 })
    ] })
  );
}

@service(fallback = new Foo())
class Foo implements Service {
  public function new() {}

  public function getFoo() {
    return 'foo';
  }
}

class Layout extends Component {
  @prop var children:Array<Widget>;

  function render() {
    return Html.create('div', {}, children);
  }
}

class Button extends Component {
  @prop var label:String;
  @prop var onClick:()->Void;  

  function render():Widget {
    return Html.create('button', {
      onclick: onClick
    }, [
      Html.text(label)
    ]);
  }
}

class NumberGoUp extends Component {
  @prop var number:Int;
  @use var foo:Foo;

  @update
  function goUp() {
    return {
      number: number + 1
    };
  }

  @update
  function goDown() {
    if (number <= 0) return {};
    return {
      number: number - 1
    };
  }

  @effect
  function track() {
    trace('Did update');
  }

  @init
  function trackInt() {
    trace('Creatin');
  }

  @before
  function trackBefore() {
    trace('Before renderin');
  }

  function render():Widget {
    return Html.create('div', {}, [
      Layout.node({
        children: [ 
          Html.text('This shouldn\'t change'),
          Html.text(foo.getFoo())
        ]
      }, 'one'),
      Button.node({
        onClick: goUp,
        label: 'Up!'
      }),
      Button.node({
        onClick: goDown,
        label: 'Down!'
      }),
      Html.create('div', {}, [
        Html.text(Std.string(number)),
      ]),
      Layout.node({
        children: [ 
          Html.text('This shouldn\'t change'),
          Html.text(foo.getFoo())
        ]
      }, 'two')
    ]);
  }
}

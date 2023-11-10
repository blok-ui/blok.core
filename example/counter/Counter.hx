package counter;

import Breeze;
import blok.html.*;
import blok.html.HtmlEvents;
import blok.ui.*;
import js.Browser;

function counter() {
  Client.mount(
    Browser.document.getElementById('counter-root'),
    () -> Html.view(<Counter key="foo" count={1} />)
  );
}

class Counter extends Component {
  @:signal final count:Int = 0;
  @:computed final countId:String = 'counter-${count()}';

  function render() return Html.view(<div
    id=countId
    className={Breeze.compose(
      Background.color('red', 500),
      Typography.textColor('white', 0),
      Typography.fontWeight('bold'),
      Spacing.pad(3),
      Spacing.margin(10),
      Border.radius(3),
    )}
  >
    // Blok requires strings to be wrapped in quotes, which is a bit
    // different than other DSLs. As a benefit of this, you can pass
    // identifiers directly as node children (like `count` here) without
    // wrapping them in brackets (like `{count}`).
    <div>'Current count: ' count</div>
    <div className={Breeze.compose(
      Flex.display(),
      Flex.gap(3),
    )}>
      // You can declare attributes as child nodes:
      <CounterButton>
        <onClick>{_ -> if (count.peek() > 0) count.update(i -> i - 1)}</onClick>
        <label>
          // Svg should Just Work.
          <svg className={Breeze.compose(
            Sizing.height(8),
            Sizing.width(8),
            Layout.display('block'),
            Svg.fill('currentColor')
          )} viewBox="0 0 40 40">
            <path d="m24.875 11.199-11.732 8.8008 11.732 8.8008 1.2012-1.6016-9.5996-7.1992 9.5996-7.1992z"/>
          </svg>
        </label>
      </CounterButton>
      // CounterButton has an @:children field, so we can just
      // pass children to it. 
      <CounterButton onClick={_ -> count.update(i -> i + 1)}>
        <svg className={Breeze.compose(
          Sizing.height(8),
          Sizing.width(8),
          Layout.display('block'),
          Svg.fill('currentColor')
        )} viewBox="0 0 40 40">
          <path d="m15.125 11.199-1.2012 1.6016 9.5996 7.1992-9.5996 7.1992 1.2012 1.6016 11.732-8.8008z"/>
        </svg>
      </CounterButton>
    </div>
  </div>);
}

class CounterButton extends Component {
  @:attribute final onClick:EventListener;
  @:children @:attribute final label:Child;

  function render() {
    return Html.view(<button className={Breeze.compose(
      Background.color('white', 0),
      Typography.textColor('red', 500),
      Typography.fontWeight('bold'),
      Spacing.pad(3),
      Border.radius(3)
    )} onClick=onClick>label</button>);
  }
}

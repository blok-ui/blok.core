package counter;

import Breeze;
import blok.html.*;
import blok.html.HtmlEvents;
import blok.html.View;
import blok.ui.*;
import js.Browser;

function counter() {
  Client.mount(
    Browser.document.getElementById('counter-root'),
    () -> Counter.node({})
  );
}

class Counter extends Component {
  @:signal final count:Int = 0;

  function render():VNode {
    return view(<div 
      id={count.map(count -> 'counter-$count')}
      className={Breeze.compose(
        Background.color('red', 500),
        Typography.textColor('white', 0),
        Typography.fontWeight('bold'),
        Spacing.pad(3),
        Spacing.margin(10), 
        Border.radius(3)
      )}
    >
      <div>"Current count: " {count.map(Std.string)}</div>
      <div className={Breeze.compose(
        Flex.display(),
        Flex.gap(3)
      )}>
        // You can declare attributes as child nodes:
        <CounterButton>
          <.onClick>{_ -> if (count.peek() > 0) count.update(i -> i - 1)}</.onClick>
          // Note: right now we don't have anything like `@:children` that will allow us
          // just to pass this to a children attribute, so you need to basically use "slots".
          <.label>
            // Svg should Just Work.
            <svg class={Breeze.compose(
              Sizing.height(8),
              Sizing.width(8),
              Layout.display('block'),
              Svg.fill('currentColor')
            )} viewBox="0 0 40 40">
              <path d="m24.875 11.199-11.732 8.8008 11.732 8.8008 1.2012-1.6016-9.5996-7.1992 9.5996-7.1992z"/>
            </svg>   
          </.label>
        </CounterButton>
        // ... or normally:
        <CounterButton onClick={_ -> count.update(i -> i + 1)} label={<svg class={Breeze.compose(
          Sizing.height(8),
          Sizing.width(8),
          Layout.display('block'),
          Svg.fill('currentColor')
        )} viewBox="0 0 40 40">
          <path d="m15.125 11.199-1.2012 1.6016 9.5996 7.1992-9.5996 7.1992 1.2012 1.6016 11.732-8.8008z"/>
        </svg>} />
      </div>
    </div>);
  }
}

class CounterButton extends Component {
  @:constant final onClick:EventListener;
  @:constant final label:Child;

  function render() {
    return view(<button class={Breeze.compose(
      Background.color('white', 0),
      Typography.textColor('red', 500),
      Typography.fontWeight('bold'),
      Spacing.pad(3),
      Border.radius(3)
    )} onClick=onClick>label</button>);
  }
}

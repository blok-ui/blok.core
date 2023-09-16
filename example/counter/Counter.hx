package counter;

import Breeze;
import blok.html.*;
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
    return Html.div({
      id: count.map(count -> 'counter-$count'),
      className: Breeze.compose(
        Background.color('red', 500),
        Typography.textColor('white', 0),
        Typography.fontWeight('bold'),
        Spacing.pad(3),
        Spacing.margin(10), 
        Border.radius(3)
      )
    }, 
      Html.div({}, 'Current count: ', count.map(Std.string)),
      Html.div({
        className: Breeze.compose(
          Flex.display(),
          Flex.gap(3)
        )
      },
        Html.button({ className: Breeze.compose(
          Background.color('white', 0),
          Typography.textColor('red', 500),
          Typography.fontWeight('bold'),
          Spacing.pad(3),
          Border.radius(3),
        ), onClick: _ -> if (count.peek() > 0) count.update(i -> i - 1) }, '-'),
        Html.button({ className: Breeze.compose(
          Background.color('white', 0),
          Typography.textColor('red', 500),
          Typography.fontWeight('bold'),
          Spacing.pad(3),
          Border.radius(3),
        ), onClick: _ -> count.update(i -> i + 1) }, '+')
      )
    );
  }
}

package counter;

import Breeze;
import blok.html.Html;
import blok.html.client.Client;
import blok.ui.*;
import js.Browser;

function counter() {
  mount(
    Browser.document.getElementById('counter-root'),
    () -> Counter.node({})
  );
}

class Counter extends ObserverComponent {
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
      Html.div({}).wrap('Current count: ', count.map(Std.string)),
      Html.button({ onClick: _ -> if (count.peek() > 0) count.update(i -> i - 1) }, '-'),
      Html.button({ onClick: _ -> count.update(i -> i + 1) }, '+')
    );
  }
}

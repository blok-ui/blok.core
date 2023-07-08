package counter;

import blok.html.Html;
import js.Browser;
import blok.html.client.Client;
import blok.ui.*;

function main() {
  mount(
    Browser.document.getElementById('counter-root'),
    Counter.node({})
  );
}

class Counter extends ObserverComponent {
  @:signal final count:Int = 0;

  function render() {
    return Html.div({ className: count.map(count -> 'counter counter-$count') }, 
      Html.div({}, 'Current count:', count.map(Std.string)),
      Html.button({ onClick: _ -> if (count.peek() > 0) count.update(i -> i - 1) }, '-'),
      Html.button({ onClick: _ -> count.update(i -> i + 1) }, '+')
    );
  }
}

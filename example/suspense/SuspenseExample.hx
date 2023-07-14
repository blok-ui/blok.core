package suspense;

import haxe.Timer;
import blok.boundary.*;
import blok.html.*;
import blok.html.client.Client;
import blok.suspense.*;
import blok.ui.*;
import js.Browser;

using Kit;

function suspense() {
  mount(Browser.document.getElementById('suspense-root'), () -> SuspenseExample.node({}));
}

class SuspenseExample extends Component {
  function render() {
    return ErrorBoundary.node({
      child: Fragment.node(
        Html.h1({}, 'Suspense Example'),
        Html.div({},
          SuspenseBoundary.node({
            child: SuspenseItem.node({ delay: 1000 }),
            fallback: () -> Html.p({}, 'Loading...')
          }),
          SuspenseBoundary.node({
            onSuspended: () -> {
              trace('Suspending...');
            },
            onComplete: () -> {
              trace('Done!');
            },
            child: Fragment.node(
              SuspenseItem.node({ delay: 1000 }),
              SuspenseItem.node({ delay: 2000 }),
              SuspenseItem.node({ delay: 3000 }),
            ),
            fallback: () -> Html.p({}, 'Loading...')
          })
        )
      ),
      fallback: (component, e, recover) -> Html.div({},
        Html.h1({}, 'Error!'),
        Html.p({}, e.message)  
      )
    });
  }
}

class SuspenseItem extends Component {
  @:constant final delay:Int;
  // @todo: This is a pretty awkward way to author resources...
  @:computed final res:Resource<String> = new Resource(() -> new Task(activate -> {
    Timer.delay(() -> activate(Ok('Loaded: ${delay}')), delay);
  }));

  function render() {
    return Html.div({}, res().get());
  }
}

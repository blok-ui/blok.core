package suspense;

import Blok.Fragment;
import haxe.Timer;
import blok.boundary.*;
import blok.html.*;
import blok.suspense.*;
import blok.ui.*;
import js.Browser;

using Kit;

function suspense() {
  Client.mount(Browser.document.getElementById('suspense-root'), () -> SuspenseExample.node({}));
}

class SuspenseExample extends Component {
  function render() {
    return ErrorBoundary.node({
      child: Fragment.node(
        Html.h1({}, 'Suspense Example'),
        Html.div({},
          SuspenseBoundaryContext.provide(
            () -> new SuspenseBoundaryContext({
              onComplete: () -> trace('Will trigger when all suspended children are complete')
            }),
            _ -> Fragment.node(
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
                // child: Html.div({},
                child: Fragment.node(
                  SuspenseItem.node({ delay: 1000 }),
                  SuspenseItem.node({ delay: 2000 }),
                  SuspenseItem.node({ delay: 3000 }),
                ),
                fallback: () -> Html.p({}, 'Loading...')
              })
            )
          )
        )
      ),
      fallback: (component, e) -> Html.div({},
        Html.h1({}, 'Error!'),
        Html.p({}, e.message)  
      )
    });
  }
}

class SuspenseItem extends Component {
  @:signal final delay:Int;
  @:resource final str:String = {
    var delay = delay();
    new Task(activate -> {
      Timer.delay(() -> activate(Ok('Loaded: ${delay}')), delay);
    });
  }

  function render() {
    return Html.div({},
      str(),
      Html.button({
        onClick: _ -> delay.update(delay -> delay + 1)
      }, 'Reload')
    );
  }
}

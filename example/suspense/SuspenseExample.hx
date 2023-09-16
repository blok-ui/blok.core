package suspense;

import Blok.Fragment;
import haxe.Timer;
import blok.boundary.*;
import blok.html.*;
import blok.suspense.*;
import blok.ui.*;
import js.Browser;

using Kit;
using Breeze;

function suspense() {
  Client.mount(Browser.document.getElementById('suspense-root'), () -> SuspenseExample.node({}));
}

class SuspenseExample extends Component {
  function render() {
    return ErrorBoundary.node({
      child: Fragment.node(
        Html.div({
          className: Breeze.compose(
            Background.color('red', 500),
            Typography.textColor('white', 0),
            Typography.fontWeight('bold'),
            Sizing.height(50),
            Spacing.pad(3),
            Spacing.margin(10), 
            Border.radius(3),
            Flex.display(),
            Flex.direction('row'),
            Flex.gap(3),
            Spacing.pad(3)
          )
        },
          SuspenseBoundaryContext.provide(
            () -> new SuspenseBoundaryContext({
              onComplete: () -> trace('Will trigger when all suspended children are complete')
            }),
            _ -> Fragment.node(
              Html.div({
                className: Breeze.compose(
                  Flex.display(),
                  Flex.direction('column'),
                  Flex.gap(3),
                  Sizing.width('50%')
                )
              }, SuspenseBoundary.node({
                child: SuspenseItem.node({ delay: 1000 }),
                fallback: () -> Html.p({}, 'Loading...')
              })),
              Html.div({
                className: Breeze.compose(
                  Flex.display(),
                  Flex.direction('column'),
                  Flex.gap(3),
                  Sizing.width('50%')
                )
              }, SuspenseBoundary.node({
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
              }))
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
        className: Breeze.compose(
          Background.color('white', 0),
          Typography.textColor('red', 500),
          Typography.fontWeight('bold'),
          Spacing.pad(3),
          Spacing.margin('left', 3), 
          Border.radius(3),
        ),
        onClick: _ -> delay.update(delay -> delay + 1)
      }, 'Reload')
    );
  }
}

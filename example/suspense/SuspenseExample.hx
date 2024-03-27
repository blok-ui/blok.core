package suspense;

import blok.boundary.*;
import blok.html.*;
import blok.suspense.*;
import blok.ui.*;
import haxe.Timer;
import js.Browser;

using Breeze;
using Kit;

function suspense() {
  Client.mount(Browser.document.getElementById('suspense-root'), () -> SuspenseExample.node({}));
}

class SuspenseExample extends Component {
  function render() {
    // Note: This component is currently using a mix of the older
    // syntax used to create vNodes and the newer, fluent builders.
    // Both are valid (and will remain so), and can be freely mixed.
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
              }).child(SuspenseBoundary.node({
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
              }).child(SuspenseBoundary.node({
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
      fallback: (component, e) -> Html.div().child([
        Html.h1().child('Error!'),
        Html.p().child(e.message)  
      ])
    });
  }
}

class SuspenseItem extends Component {
  @:signal final delay:Int;

  // A 'resource' represents an asynchronous value of some sort. When
  // used in a Component, it will trigger a suspense that can be
  // handled by the closest SuspenseBoundary ancestor. Once
  // the Resource is ready, the SuspenseBoundary will remount the 
  // suspended component.
  //
  // Note that using resources outside of a SuspenseBoundary will cause
  // an error to be thrown.
  @:resource final str:String = {
    // Resources are also Computations, meaning that they will
    // automatically re-fetch whenever a signal changes (such
    // as "delay" here):
    var delay = delay();
    new Task(activate -> {
      Timer.delay(() -> activate(Ok('Loaded: ${delay}')), delay);
    });
  }

  function render() {
    return Html.div()
      .child(str()) // Suspense is potentially triggered here.
      .child(
        Html.button()
          .attr(HtmlAttributeName.ClassName, Breeze.compose(
            Background.color('white', 0),
            Typography.textColor('red', 500),
            Typography.fontWeight('bold'),
            Spacing.pad(3),
            Spacing.margin('left', 3), 
            Border.radius(3),
          ))
          .on(Click, _ -> delay.update(delay -> delay + 1))
          .child('Reload')
      );
  }
}

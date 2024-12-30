package suspense;

import blok.context.*;
import blok.html.*;
import blok.suspense.*;
import blok.ui.*;
import haxe.Timer;

using Breeze;
using Kit;
using blok.boundary.BoundaryModifiers;
using blok.suspense.SuspenseModifiers;

function suspense() {
	Client.mount('#suspense-root', SuspenseExample.node({}));
}

class SuspenseExample extends Component {
	function render() {
		var body = Provider.provide(new SuspenseBoundaryContext({
			onComplete: () -> trace('Will trigger when all suspended children are complete')
		})).child(Fragment.of([
			Html.div({
				className: Breeze.compose(
					Flex.display(),
					Flex.direction('column'),
					Flex.gap(3),
					Sizing.width('50%')
				)
			}).child(
				SuspenseItem.node({delay: 1000})
					.inSuspense(() -> Html.p().child('Loading...'))
			).node(),
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
				child: Fragment.of([
					SuspenseItem.node({delay: 1000}),
					SuspenseItem.node({delay: 2000}),
					SuspenseItem.node({delay: 3000}),
				]),
				fallback: () -> Html.p().child('Loading...')
			})),
			Html.div()
				.child(
					Html.p()
						.child('Never suspends')
						.inSuspense(() -> Html.p().child('You should not see this'))
						.onComplete(() -> trace('This component never suspends, so onComplete is called right away'))
						.onSuspended(() -> throw 'oh no')
						.node()
				)
		]));

		return Html.div({
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
		}).child(body)
			.inErrorBoundary((component, e) -> Html.div().child([
				Html.h1().child('Error!'),
				Html.p().child(e.message)
			]));
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
			.attr(ClassName, Breeze.compose(
				Flex.display()
			))
				// .child(str())
			.child(SubItem.node({str: str})) // Resources can be passed as ReadOnlySignals
			.child(
				Html.button()
					.attr(ClassName, Breeze.compose(
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

class SubItem extends Component {
	@:observable final str:String;

	function render():Child {
		return Html.div()
			.attr(ClassName, Breeze.compose(
				Background.color('red', 300)
			))
			.child(str);
	}
}

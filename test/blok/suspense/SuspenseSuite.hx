package blok.suspense;

import blok.ui.*;
import blok.context.Provider;
import blok.html.Server;
import haxe.Timer;
import blok.suspense.Resource;
import blok.ui.Scope;
import blok.suspense.SuspenseBoundary;
import blok.html.server.*;

class SuspenseSuite extends Suite {
	@:test(expects = 1)
	function testSimpleSuspension() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			var resource = new Resource(() -> new Task(activate -> {
				Timer.delay(() -> activate(Ok('Hello world')), 100);
			}));
			mount(document, () -> SuspenseBoundary.node({
				onComplete: () -> {
					document.toString({includeTextMarkers: false}).equals('Hello world');
					activate(Nothing);
				},
				fallback: () -> 'Loading...',
				child: Scope.wrap(_ -> resource())
			}));
		});
	}

	@:test(expects = 6)
	function testNestedSuspensions() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			var resource1 = new Resource(() -> new Task(activate -> {
				Timer.delay(() -> activate(Ok('Hello world')), 100);
			}));
			var resource2 = new Resource(() -> new Task(activate -> {
				Timer.delay(() -> activate(Ok('Hello other world')), 150);
			}));
			mount(document, () -> Provider
				.provide(() -> new SuspenseBoundaryContext({
					onSuspended: () -> Assert.pass(),
					onComplete: () -> {
						document.toString({includeTextMarkers: false}).equals('Hello world | Hello other world');
						activate(Nothing);
					}
				}))
				.child(_ -> SuspenseBoundary.node({
					onSuspended: () -> Assert.pass(),
					onComplete: () -> Assert.pass(),
					fallback: () -> 'loading...',
					child: Scope.wrap(_ -> Fragment.of([
						Text.node(resource1()),
						Text.node(' | '),
						SuspenseBoundary.node({
							onSuspended: () -> Assert.pass(),
							onComplete: () -> Assert.pass(),
							fallback: () -> 'loading...',
							child: Scope.wrap(_ -> resource2())
						}),
					]))
				}))
			);
		});
	}

	@:test(expects = 1)
	function suspenseBoundaryContextWillStillTriggerOnCompleteOnceIfNotSuspended() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			mount(document, () -> Provider
				.provide(() -> new SuspenseBoundaryContext({
					onSuspended: () -> Assert.fail('Should not have suspended'),
					onComplete: () -> {
						document.toString({includeTextMarkers: false}).equals('Hello world');
						activate(Nothing);
					}
				}))
				.child(_ -> SuspenseBoundary.node({
					onSuspended: () -> Assert.fail('Should not have suspended'),
					fallback: () -> 'loading...',
					child: Scope.wrap(_ -> Fragment.of([
						Text.node('Hello '),
						SuspenseBoundary.node({
							onSuspended: () -> Assert.fail('Should not have suspended'),
							fallback: () -> 'loading...',
							child: Scope.wrap(_ -> 'world')
						}),
					]))
				}))
			);
		});
	}
}

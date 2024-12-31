package blok;

import blok.Scheduler;
import blok.Provider;
import blok.html.Server;
import haxe.Timer;
import blok.signal.Resource;
import blok.Scope;
import blok.SuspenseBoundary;
import blok.html.server.*;

using blok.BoundaryModifiers;

class SuspenseSuite extends Suite {
	@:test(expects = 1)
	function testSimpleSuspension() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			var resource = new Resource(() -> new Task(activate -> {
				Timer.delay(() -> activate(Ok('Hello world')), 100);
			}));
			mount(document, SuspenseBoundary.node({
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
	function nestedSuspensionsWork() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			var resource1 = new Resource(() -> new Task(activate -> {
				Timer.delay(() -> activate(Ok('Hello world')), 100);
			}));
			var resource2 = new Resource(() -> new Task(activate -> {
				Timer.delay(() -> activate(Ok('Hello other world')), 150);
			}));
			mount(document, Provider
				.provide(new SuspenseBoundaryContext({
					onSuspended: () -> Assert.pass(),
					onComplete: () -> {
						document.toString({includeTextMarkers: false}).equals('Hello world | Hello other world');
						activate(Nothing);
					}
				}))
				.child(SuspenseBoundary.node({
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

	@:test(expects = 2)
	function suspenseBoundaryWillNotTriggerOnCompleteIfResourceFails() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			var resource = new Resource<String>(() -> new Task(activate -> {
				Scheduler
					.current()
					.schedule(() -> activate(Error(new Error(InternalError, 'Failed intentionally'))));
			}));
			mount(document, SuspenseBoundary.node({
				onSuspended: () -> Assert.pass(),
				onComplete: () -> Assert.fail('Should not run on complete'),
				fallback: () -> 'loading...',
				child: Scope.wrap(_ -> resource())
			}).inErrorBoundary((component, e) -> {
				e.message.equals('Failed intentionally');
				Scheduler.current().schedule(() -> activate(Nothing));
				Placeholder.node();
			}));
		});
	}

	@:test(expects = 1)
	function suspenseBoundaryWillNotTriggerOnCompleteIfResourceFailsImmediately() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			var resource = new Resource<String>(() -> Task.reject(new Error(InternalError, 'Failed intentionally')));
			mount(document, SuspenseBoundary.node({
				onSuspended: () -> Assert.fail('Should not have suspended'),
				onComplete: () -> Assert.fail('Should not run on complete'),
				fallback: () -> 'loading...',
				child: Scope.wrap(_ -> resource())
			}).inErrorBoundary((component, e) -> {
				e.message.equals('Failed intentionally');
				Scheduler.current().schedule(() -> activate(Nothing));
				Placeholder.node();
			}));
		});
	}

	@:test(expects = 1)
	function suspenseBoundaryWillStillTriggerOnCompleteIfNotSuspended() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			mount(document, SuspenseBoundary.node({
				onSuspended: () -> Assert.fail('Should not have suspended'),
				onComplete: () -> {
					document.toString({includeTextMarkers: false}).equals('Hello world');
					activate(Nothing);
				},
				fallback: () -> 'loading...',
				child: Scope.wrap(_ -> 'Hello world')
			}));
		});
	}

	@:test(expects = 1)
	function suspenseBoundaryContextWillStillTriggerOnCompleteOnceIfNotSuspended() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			mount(document, Provider
				.provide(new SuspenseBoundaryContext({
					onSuspended: () -> Assert.fail('Should not have suspended'),
					onComplete: () -> {
						document.toString({includeTextMarkers: false}).equals('Hello world');
						activate(Nothing);
					}
				}))
				.child(SuspenseBoundary.node({
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

	@:test(expects = 3)
	function suspenseBoundaryContextWillNotTriggerOnCompleteIfResourceFails() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			var resource = new Resource<String>(() -> new Task(activate -> {
				Scheduler
					.current()
					.schedule(() -> activate(Error(new Error(InternalError, 'Failed intentionally'))));
			}));
			mount(document, Provider
				.provide(new SuspenseBoundaryContext({
					onSuspended: () -> Assert.pass(),
					onComplete: () -> Assert.fail('Should not run on complete')
				}))
				.child(SuspenseBoundary.node({
					onSuspended: () -> Assert.pass(),
					fallback: () -> 'loading...',
					child: Scope.wrap(_ -> resource())
				}))
				.node()
				.inErrorBoundary((component, e) -> {
					e.message.equals('Failed intentionally');
					Scheduler.current().schedule(() -> activate(Nothing));
					Placeholder.node();
				})
			);
		});
	}

	@:test(expects = 1)
	function suspenseBoundaryContextWillNotTriggerOnCompleteIfResourceFailsImmediately() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			var resource = new Resource<String>(() -> Task.reject(new Error(InternalError, 'Failed intentionally')));
			mount(document, Provider
				.provide(new SuspenseBoundaryContext({
					onSuspended: () -> Assert.fail('Should not have suspended'),
					onComplete: () -> Assert.fail('Should not run on complete')
				}))
				.child(SuspenseBoundary.node({
					onSuspended: () -> Assert.fail('Should not have suspended'),
					fallback: () -> 'loading...',
					child: Scope.wrap(_ -> resource())
				}))
				.node()
				.inErrorBoundary((component, e) -> {
					e.message.equals('Failed intentionally');
					Scheduler.current().schedule(() -> activate(Nothing));
					Placeholder.node();
				})
			);
		});
	}
}

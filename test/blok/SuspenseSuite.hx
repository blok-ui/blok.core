package blok;

import blok.*;
import blok.core.*;
import blok.html.Server;
import blok.html.server.*;
import blok.signal.Resource;
import haxe.Timer;

using blok.Modifiers;

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
							fallback: () -> 'Loading...',
							child: Scope.wrap(_ -> resource2())
						}),
					]))
				}))
			);
		});
	}

	@:test(expects = 1)
	function errorBoundariesWillTryToPassSuspenseExceptionsUpwards() {
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
				child: Scope
					.wrap(_ -> resource())
					.inErrorBoundary((e) -> {
						Assert.fail('Error boundary was used instead');
						'Fail';
					})
			}));
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
			}).inErrorBoundary((e) -> {
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
			var resource = new Resource<String>(() -> Task.error(new Error(InternalError, 'Failed intentionally')));
			mount(document, SuspenseBoundary.node({
				onSuspended: () -> Assert.fail('Should not have suspended'),
				onComplete: () -> Assert.fail('Should not run on complete'),
				fallback: () -> 'loading...',
				child: Scope.wrap(_ -> resource())
			}).inErrorBoundary((e) -> {
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

	@:test(expects = 4)
	function suspenseBoundaryContextWillTriggerOnCompleteIfResourceFails() {
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
					onComplete: () -> {
						Assert.pass();
						activate(Nothing);
					}
				}))
				.child(SuspenseBoundary.node({
					onSuspended: () -> Assert.pass(),
					fallback: () -> 'loading...',
					child: Scope.wrap(_ -> resource())
				}))
				.node()
				.inErrorBoundary((e) -> {
					e.message.equals('Failed intentionally');
					Placeholder.node();
				})
			);
		});
	}

	@:test(expects = 2)
	function suspenseBoundaryContextWillTriggerOnCompleteIfResourceFailsImmediately() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			var resource = new Resource<String>(() -> Task.error(new Error(InternalError, 'Failed intentionally')));
			mount(document, Provider
				.provide(new SuspenseBoundaryContext({
					onSuspended: () -> Assert.fail('Should not have suspended'),
					onComplete: () -> {
						Assert.pass();
						activate(Nothing);
					}
				}))
				.child(SuspenseBoundary.node({
					onSuspended: () -> Assert.fail('Should not have suspended'),
					fallback: () -> 'loading...',
					child: Scope.wrap(_ -> resource())
				}))
				.node()
				.inErrorBoundary((e) -> {
					e.message.equals('Failed intentionally');
					Placeholder.node();
				})
			);
		});
	}
}

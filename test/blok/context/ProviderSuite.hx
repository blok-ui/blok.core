package blok.context;

import blok.ui.*;
import blok.html.Server;
import blok.html.server.*;

using blok.boundary.BoundaryModifiers;
using blok.suspense.SuspenseModifiers;

class ProviderSuite extends Suite {
	@:test(expects = 3)
	function providesContextToChildren() {
		var test:Null<TestContext> = new TestContext('foo');
		return render(Provider
			.provide(test)
			.child(Scope.wrap(context -> {
				var test = TestContext.from(context);
				test.value.equals('foo');
				'ok';
			}))
		).flatMap(root -> new Future(activate -> {
			root.getAdaptor().schedule(() -> {
				test.disposed.equals(false);
				root.dispose();
				test.disposed.equals(true);
				activate(Nothing);
			});
		}));
	}

	@:test(expects = 3)
	function sharedContextIsNotDisposed() {
		var test:Null<TestContext> = new TestContext('foo');
		return render(Provider
			.share(test)
			.child(Scope.wrap(context -> {
				var test = TestContext.from(context);
				test.value.equals('foo');
				'ok';
			}))
		).flatMap(root -> new Future(activate -> {
			root.getAdaptor().schedule(() -> {
				test.disposed.equals(false);
				root.dispose();
				test.disposed.equals(false);
				activate(Nothing);
			});
		}));
	}

	@:test(expects = 3)
	function fallsBackToDefault() {
		var test:Null<TestContext> = null;
		return render(Scope.wrap(context -> {
			test = TestContext.from(context);
			test.value.equals('default');
			'ok';
		})).flatMap(root -> new Future(activate -> {
			root.getAdaptor().schedule(() -> {
				test.disposed.equals(false);
				root.dispose();
				test.disposed.equals(true);
				activate(Nothing);
			});
		}));
	}

	// @todo: We need a test framework that will let us test things when
	// the view re-renders.
}

private function render(body:Child):Future<Null<View>> {
	return new Future(activate -> {
		var root:Null<View> = null;
		var doc = new ElementPrimitive('#document');
		root = mount(doc, body
			.inSuspense(() -> '...')
			.onComplete(() -> activate(root))
			.node()
			.inErrorBoundary((component, e) -> throw e)
		);
	});
}

@:fallback(new TestContext('default'))
class TestContext implements Context {
	public final value:String;
	public var disposed:Bool = false;

	public function new(value) {
		this.value = value;
	}

	public function dispose() {
		this.disposed = true;
	}
}

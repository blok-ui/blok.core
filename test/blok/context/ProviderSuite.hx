package blok.context;

import blok.ui.*;
import blok.html.Server;
import blok.html.server.*;

using blok.boundary.BoundaryModifiers;
using blok.suspense.SuspenseModifiers;

class ProviderSuite extends Suite {
	@:test(expects = 1)
	function providesContextToChildren() {
		return new Future(activate -> {
			render(activate, Provider
				.provide(new TestContext('foo'))
				.child(Scope.wrap(context -> {
					var test = TestContext.from(context);
					test.value.equals('foo');
					'ok';
				}))
			);
		});
	}

	@:test(expects = 1)
	function fallsBackToDefault() {
		return new Future(activate -> {
			render(activate, Scope.wrap(context -> {
				var test = TestContext.from(context);
				test.value.equals('default');
				'ok';
			}));
		});
	}

	// @todo: We need a test framework that will let us test things when
	// the view re-renders.
}

private function render(activate:(value:Any) -> Void, body:Child) {
	var root = new ElementPrimitive('#document');
	mount(root, body
		.inSuspense(() -> '...')
		.onComplete(() -> activate(Nothing))
		.node()
		.inErrorBoundary((component, e) -> throw e)
	);
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

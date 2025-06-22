package blok;

class ProviderSuite extends Suite {
	@:test(expects = 3)
	function providesContextToChildren() {
		var test:Null<TestContext> = new TestContext('foo');
		return sandbox.render(
			Provider
				.provide(test)
				.child(Scope.wrap(context -> {
					var test = TestContext.from(context);
					test.value.equals('foo');
					'ok';
				}))
		).then(root -> {
			test.disposed.equals(false);
			root.dispose();
			test.disposed.equals(true);
			Task.nothing();
		});
	}

	@:test(expects = 3)
	function sharedContextIsNotDisposed() {
		var test:Null<TestContext> = new TestContext('foo');
		return sandbox.render(
			Provider
				.share(test)
				.child(Scope.wrap(context -> {
					var test = TestContext.from(context);
					test.value.equals('foo');
					'ok';
				}))
		).then(root -> {
			test.disposed.equals(false);
			root.dispose();
			test.disposed.equals(false);
			Task.nothing();
		});
	}

	@:test(expects = 3)
	function fallsBackToDefault() {
		var test:Null<TestContext> = null;
		return sandbox.render(
			Scope.wrap(context -> {
				test = TestContext.from(context);
				test.value.equals('default');
				'ok';
			})
		).then(root -> {
			test.disposed.equals(false);
			root.dispose();
			test.disposed.equals(true);
			Task.nothing();
		});
	}

	@:test(expects = 6)
	function fallbacksAreSharedPerView() {
		var test1:Null<TestContext> = null;
		var test2:Null<TestContext> = null;

		return sandbox.render(
			Scope.wrap(context -> {
				test1 = TestContext.from(context);
				test2 = TestContext.from(context);
				test1.value.equals('default');
				test2.value.equals('default');
				test1.equals(test2);
				'ok';
			})
		).then(root -> {
			test1.disposed.equals(false);
			root.dispose();
			test1.disposed.equals(true);
			test2.disposed.equals(true);
			Task.nothing();
		});
	}

	@:test(expects = 2)
	function testProvidersReRender() {
		var view = sandbox.wrap(
			Provider.provide(new TestContext('foo')).child(Scope.wrap(context -> {
				TestContext.from(context).value;
			}))
		);

		return view.mount()
			.then(root -> {
				root.primitive.toString({includeTextMarkers: false}).equals('foo');
				view.update(Provider.provide(new TestContext('bar')).child(Scope.wrap(context -> {
					TestContext.from(context).value;
				})));
			})
			.then(root -> {
				root.primitive.toString({includeTextMarkers: false}).equals('bar');
				root.dispose();
				Task.nothing();
			});
	}
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

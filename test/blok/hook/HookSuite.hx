package blok.hook;

import blok.ui.*;

class HookSuite extends Suite {
	@:test(expects = 4)
	function hooksWorkCorrectly() {
		return HookedComponent
			.node({})
			.renderAsync()
			.flatMap(root -> new Future(activate -> {
				var comp = root.findChildOfType(HookedComponent, true).orThrow();
				comp.hook.value.equals('foo');
				comp.hook.wasSetup.equals(true);
				comp.hook.disposed.equals(false);
				root.getAdaptor().schedule(() -> {
					root.dispose();
					comp.hook.disposed.equals(true);
					activate(Nothing);
				});
			}));
	}
}

class HookedComponent extends Component {
	@:use public final hook:HookExample = new HookExample('foo');

	function render():Child {
		return hook.value;
	}
}

class HookExample implements Hook {
	public final value:String;
	public var wasSetup:Bool = false;
	public var disposed:Bool = false;

	public function new(value) {
		this.value = value;
	}

	public function setup(view:View) {
		wasSetup = true;
	}

	public function dispose() {
		this.disposed = true;
	}
}

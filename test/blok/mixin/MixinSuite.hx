package blok.mixin;

import blok.ui.*;
import blok.signal.Signal;

class MixinSuite extends Suite {
	@:test(expects = 3)
	function mixinsWorkCorrectly() {
		return MixedComponent
			.node({})
			.renderAsync()
			.flatMap(root -> new Future(activate -> {
				var comp = root.findChildOfType(MixedComponent, true).orThrow();
				comp.mix.isSetup.equals(true);
				comp.mix.value.peek().equals('foo');
				comp.mix.viewHasFooBar.equals(true);

				root.getAdaptor().schedule(() -> {
					root.dispose();
					activate(Nothing);
				});
			}));
	}
}

class MixedComponent extends Component {
	@:use public final mix:MixinExample;

	@:attribute public final value:String = 'foo';
	@:signal public final foo:String = 'foo';
	@:computed public final fooBar:String = foo() + 'bar';

	function render():Child {
		return value;
	}
}

class MixinExample extends Mixin<{
	@:attribute final value:String;
	@:signal final foo:String;
	@:computed final fooBar:String;
}> {
	@:computed public final value:String = view.value;

	public var isSetup:Bool = false;
	public var viewHasFooBar:Bool = false;

	public function new() {
		isSetup = true;
	}

	@:effect function testThatEffectsRun():Void {
		viewHasFooBar = view.fooBar() == 'foobar';
	}
}

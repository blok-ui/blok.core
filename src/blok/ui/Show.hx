package blok.ui;

import blok.signal.Signal;

final class Show extends Component {
	public inline static function when(condition:ReadOnlySignal<Bool>, child:() -> Child) {
		return new VShow({condition: condition, child: child});
	}

	@:deprecated('Use `when` and manually invert the condition. Don\'t directly create a signal in Components.')
	public inline static function unless(condition:ReadOnlySignal<Bool>, child:() -> Child) {
		return new VShow({condition: new blok.signal.Computation(() -> !condition()), child: child});
		// return new VShow({condition: condition.map(c -> !c), child: child});
	}

	@:observable final condition:Bool;
	@:attribute final otherwise:Null<() -> Child> = null;
	@:children @:attribute final child:() -> Child;

	function render() {
		return if (condition()) {
			child();
		} else if (otherwise != null) {
			otherwise();
		} else {
			Placeholder.node();
		}
	}
}

typedef VShowData = {
	condition:ReadOnlySignal<Bool>,
	child:() -> Child,
	?otherwise:() -> Child
}

abstract VShow(VShowData) {
	public function new(data) {
		this = data;
	}

	public function otherwise(build:() -> Child) {
		this.otherwise = build;
		return abstract;
	}

	@:to
	public inline function node():Child {
		return Show.node({
			condition: this.condition,
			child: this.child,
			otherwise: this.otherwise
		});
	}

	@:to
	public inline function toChildren():Children {
		return node();
	}
}

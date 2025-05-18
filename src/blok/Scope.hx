package blok;

import blok.engine.IntoView;

class Scope extends Component {
	public inline static function wrap(child) {
		return node({child: child});
	}

	@:children @:attribute final child:(context:IntoView) -> Child;

	function render():Child {
		return child(this);
	}
}

package blok;

import blok.engine.ViewContext;

class Scope extends Component {
	public inline static function wrap(child) {
		return node({child: child});
	}

	@:children @:attribute final child:(context:ViewContext) -> Child;

	function render():Child {
		return child(this);
	}
}

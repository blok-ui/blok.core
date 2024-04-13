package blok.ui;

class Scope extends Component {
	public inline static function wrap(child) {
		return node({child: child});
	}

	@:children @:attribute final child:(context:Component) -> Child;

	function render():VNode {
		return child(this);
	}
}

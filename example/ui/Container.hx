package ui;

import blok.*;
import Breeze;

class Container extends Component {
	@:attribute final styles:ClassName = null;
	@:children @:attribute final children:Children;

	public function render():Child {
		return Panel.node({
			styles: Breeze.compose(
				Spacing.margin('x', 'auto'),
				Spacing.margin('y', 10),
				Breakpoint.viewport('700px', Sizing.width('700px'))
			),
			children: children
		});
	}
}

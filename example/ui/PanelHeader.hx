package ui;

import blok.*;
import blok.html.Html;
import Breeze;

class PanelHeader extends Component {
	@:attribute final styles:ClassName = null;
	@:children @:attribute final children:Children;

	public function render():Child {
		return Html.header({
			className: Breeze.compose(
				styles,
				Flex.display(),
				Flex.gap(3),
				Flex.alignItems('center'),
				Spacing.margin('x', 3),
				Spacing.pad('y', 3),
				Border.width('bottom', .5)
			)
		}).child(children);
	}
}

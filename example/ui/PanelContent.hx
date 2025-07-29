package ui;

import blok.*;
import blok.html.Html;
import Breeze;

class PanelContent extends Component {
	@:attribute final styles:ClassName = null;
	@:children @:attribute final children:Children;

	public function render():Child {
		return Html.div({
			className: Breeze.compose(
				styles,
				Spacing.pad(3)
			)
		}).child(children);
	}
}

package ui;

import blok.*;
import blok.html.Html;
import Breeze;

class Panel extends Component {
	@:attribute final styles:ClassName = null;
	@:children @:attribute final children:Children;

	public function render():Child {
		return Html.div({
			className: Breeze.compose(
				styles,
				Border.radius(3),
				Border.width(.5)
			)
		}).child(children);
	}
}

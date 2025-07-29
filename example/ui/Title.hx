package ui;

import blok.*;
import blok.html.Html;
import Breeze;

class Title extends Component {
	@:attribute final styles:ClassName = null;
	@:children @:attribute final children:Children;

	public function render():Child {
		return Html.h2({
			className: Breeze.compose(
				styles,
				Typography.fontSize('lg'),
				Typography.fontWeight('bold')
			)
		}).child(children);
	}
}

package ui;

import blok.*;
import blok.html.Html;
import Breeze;

class Button extends Component {
	@:attribute final action:() -> Void;
	@:children @:attribute final children:Children;
	@:observable final selected:Bool = false;
	@:computed final className:ClassName = [
		Spacing.pad('x', 3),
		Spacing.pad('y', 1),
		Border.radius(3),
		Border.width(.5),
		Border.color('black', 0),
		if (selected()) Breeze.compose(
			Background.color('black', 0),
			Typography.textColor('white', 0)
		) else Breeze.compose(
			Background.color('white', 0),
			Typography.textColor('black', 0),
			Modifier.hover(
				Background.color('gray', 200)
			)
		)
	];

	function render() {
		return Html.button({
			className: className,
			onClick: _ -> action()
		}).child(children);
	}
}

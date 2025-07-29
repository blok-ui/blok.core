package ui;

import haxe.Exception;
import blok.*;
import blok.html.Html;
import Breeze;

class ErrorView extends Component {
	@:attribute public final exception:Exception;

	public function render():Child {
		return Panel.node({
			styles: Breeze.compose(
				Background.color('red', 500),
				Typography.textColor('white', 0),
			),
			children: PanelContent.node({
				children: [
					Html.strong({
						className: Typography.fontWeight('bold')
					}).child('Error'),
					Text.ofString(exception.toString())
				]
			})
		});
	}
}

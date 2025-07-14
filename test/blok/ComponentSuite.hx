package blok;

import blok.signal.Signal;
import blok.html.Html;
import blok.*;

class ComponentSuite extends Suite {
	@:test
	function componentRendersCorrectly() {
		return sandbox
			.render(SimpleComponent.node({value: 'value'}))
			.then(root -> {
				root.primitive.toString({includeTextMarkers: false}).equals('<div>value</div>');
				Task.nothing();
			});
	}

	@:test
	function componentReactsToSignals() {
		var value = new Signal('value');
		return sandbox
			.render(ReactiveComponent.node({value: value}))
			.then(root -> {
				root.primitive.toString({includeTextMarkers: false}).equals('<div>value</div>');
				value.set('new value');
				// @todo: We need a more robust way to do this! Our scheduling system remains
				// a bit of a mess.
				new Task(activate -> {
					root.adaptor.scheduleEffect(() -> root.adaptor.scheduleEffect(() -> {
						root.primitive.toString({includeTextMarkers: false}).equals('<div>new value</div>');
						activate(Ok(Nothing));
					}));
				});
			});
	}
}

class SimpleComponent extends Component {
	@:attribute final value:String;

	function render():Child {
		return Html.div().child(value);
	}
}

class ReactiveComponent extends Component {
	@:observable final value:String;

	function render():Child {
		return SimpleComponent.node({value: value()});
	}
}

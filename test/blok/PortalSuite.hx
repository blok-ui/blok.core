package blok;

import blok.html.Html;
import blok.html.server.*;

class PortalSuite extends Suite {
	@:test(expects = 2)
	function portalWillRenderChildrenInTheGivenPrimitive() {
		var portalRoot = new ElementPrimitive('div', {id: 'portal'});
		return Html.div().child(
			Portal.node({
				target: portalRoot,
				child: Html.p().child('Test')
			}),
			Html.p().child('Body')
		).node()
			.renderAsync()
			.flatMap(root -> new Future(activate -> {
				root.getAdaptor().scheduleEffect(() -> {
					var document:NodePrimitive = cast root.getPrimitive();
					document.toString({includeTextMarkers: false}).equals('<div><p>Body</p></div>');
					portalRoot.toString({includeTextMarkers: false}).equals('<div id="portal"><p>Test</p></div>');
					root.dispose();
					activate(Nothing);
				});
			}));
	}
}

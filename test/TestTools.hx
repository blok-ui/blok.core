import blok.ui.*;
import blok.html.Server;
import blok.html.server.*;

using blok.boundary.BoundaryModifiers;
using blok.suspense.SuspenseModifiers;

function renderAsync(body:Child):Future<Null<View>> {
	return new Future(activate -> {
		var root:Null<View> = null;
		var doc = new ElementPrimitive('#document');
		root = mount(doc, body
			.inSuspense(() -> '...')
			.onComplete(() -> activate(root))
			.node()
			.inErrorBoundary((component, e) -> throw e)
		);
	});
}

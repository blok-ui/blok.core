import blok.*;
import blok.engine.*;
import blok.html.Server;
import blok.html.server.*;

using blok.Modifiers;

function renderAsync(body:Child):Future<Null<Root>> {
	return new Future(activate -> {
		var root:Null<Root> = null;
		var doc = new ElementPrimitive('#document');
		root = new Root(doc, new ServerAdaptor(), body
			.inSuspense(() -> '...')
			.onComplete(() -> activate(root))
			.node()
			.inErrorBoundary((e) -> throw e)
		);
		root.mount();

		// var root:Null<View> = null;
		// root = mount(doc, body
		// 	.inSuspense(() -> '...')
		// 	.onComplete(() -> activate(root))
		// 	.node()
		// 	.inErrorBoundary((e) -> throw e)
		// ).orThrow();
	});
}

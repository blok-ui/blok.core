package blok.suspense;

import blok.html.Server;
import haxe.Timer;
import blok.suspense.Resource;
import blok.ui.Scope;
import blok.suspense.SuspenseBoundary;
import blok.html.server.*;

class SuspenseSuite extends Suite {
	@:test(expects = 1)
	function testSimpleScheduling() {
		return new Future(activate -> {
			var document = new ElementPrimitive('#document');
			var resource = new Resource(() -> new Task(activate -> {
				Timer.delay(() -> activate(Ok('Hello world')), 100);
			}));
			mount(document, () -> SuspenseBoundary.node({
				onComplete: () -> {
					document.toString({includeTextMarkers: false}).equals('Hello world');
					activate(Nothing);
				},
				fallback: () -> 'Loading...',
				child: Scope.wrap(_ -> resource())
			}));
		});
	}
	// @todo: more! gotta test nested stuff
}

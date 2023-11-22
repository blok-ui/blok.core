package blok;

import blok.signal.Graph;
import blok.core.DisposableCollection;
import blok.signal.*;

class Signals extends Suite {
	function execute() {
		describe('blok.signal.Observer', () -> {
			it('should react to changes in state', spec -> scope(() -> {
				spec.expect(2);

				var value = 'foo';
				var signal = new Signal(value);
				
				Observer.track(() -> {
					signal.get().should().be(value);
				});

				value = 'bar';
				signal.set(value);
			}));
		});
	}

	function scope(fn:()->Void) {
		var disposables = new DisposableCollection();
		withOwner(disposables, fn);
		disposables.dispose();
	}
}

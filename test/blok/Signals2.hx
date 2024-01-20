package blok;

import blok.signal.*;

@:access(blok.signal)
class Signals2 extends Suite {
	function execute() {
		describe('blok.signal2.Observer', () -> {
			it('should react to changes in state', spec -> {
				spec.expect(2);

				var value = 'foo';
				var signal = new Signal(value);

				return new Future(activate -> {
					Observer.track(() -> {
						signal.get().should().be(value);
						if (value == 'bar') activate(Ok);
					});
	
					value = 'bar';
					signal.set(value);
				});
			});
			it('should not react to changes in state when the consumer is disposed', spec -> {
				spec.expect(4);

				var value = 'foo';
				var signal = new Signal(value);

				return new Future(activate -> {
					var node = signal.node;
					var observer = new Observer(() -> {
						signal.get().should().be(value);
					});

					node.consumers.should().notBe(null);
					node.consumers.length.should().be(1);

					observer.dispose();

					node.consumers.length.should().be(0);

					value = 'bar';
					signal.set(value);

					Runtime.current().schedule(() -> activate(Ok));
				});
			});
		});

		describe('blok.signal2.Computed', () -> {
			it('should react to changes in state', spec -> {
				spec.expect(2);

				var value = 'foo';
				var signal = new Signal(value);
				var computed = new Computation(() -> signal() + ' foo');
				var computed2 = new Computation(() -> computed() + ' bar');

				return new Future(activate -> {
					Observer.track(() -> {
						computed2.get().should().be(value + ' foo bar');
						if (value == 'bar') activate(Ok);
					});

					value = 'bar';
					signal.set(value);
				});
			});
		});
	}
}

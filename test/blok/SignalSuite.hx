package blok;

import blok.signal.*;

@:access(blok.signal)
class SignalSuite extends Suite {
	@:test(expects = 2)
	function observerShouldReactToChangesInSignals() {
		var value = 'foo';
		var signal = new Signal(value);
		return new Future(activate -> {
			Observer.track(() -> {
				signal.get().equals(value);
				if (value == 'bar') activate(Ok);
			});
			value = 'bar';
			signal.set(value);
		});
	}

	@:test(expects = 4)
	function shouldNotReactToChangesInStateWhenConsumerIsDisposed() {
		var value = 'foo';
		var signal = new Signal(value);
		return new Future(activate -> {
			var node = signal.node;
			var observer = new Observer(() -> {
				signal.get().equals(value);
			});
			(node.consumers == null).equals(false);
			node.consumers.length.equals(1);
			observer.dispose();
			node.consumers.length.equals(0);
			value = 'bar';
			signal.set(value);
			Runtime.current().schedule(() -> activate(Ok));
		});
	}

	@:test(expects = 2)
	function consumersShouldReactToSignalChanges() {
		var value = 'foo';
		var signal = new Signal(value);
		var computed = new Computation(() -> signal() + ' foo');
		var computed2 = new Computation(() -> computed() + ' bar');
		return new Future(activate -> {
			Observer.track(() -> {
				computed2.get().equals(value + ' foo bar');
				if (value == 'bar') activate(Ok);
			});
			value = 'bar';
			signal.set(value);
		});
	}
}

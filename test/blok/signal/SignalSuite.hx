package blok.signal;

import blok.core.Owner;

@:access(blok.signal)
class SignalSuite extends Suite {
	@:test(expects = 2)
	function observerShouldReactToChangesInSignals() {
		var value = 'foo';
		var signal = new Signal(value);
		return new Task(activate -> {
			Observer.track(() -> {
				signal.get().equals(value);
				if (value == 'bar') activate(Ok(Nothing));
			});
			value = 'bar';
			signal.set(value);
		});
	}

	@:test(expects = 4)
	function shouldNotReactToChangesInStateWhenConsumerIsDisposed() {
		var value = 'foo';
		var signal = new Signal(value);
		return new Task(activate -> {
			var observer = new Observer(() -> {
				signal.get().equals(value);
			});
			(signal.node.consumers == null).equals(false);
			signal.node.consumers.length.equals(1);
			observer.dispose();
			signal.node.consumers.length.equals(0);
			value = 'bar';
			signal.set(value);
			Runtime.current().schedule(() -> activate(Ok(Nothing)));
		});
	}

	@:test(expects = 2)
	function consumersShouldReactToSignalChanges() {
		var value = 'foo';
		var signal = new Signal(value);
		var computed = new Computation(() -> signal() + ' foo');
		var computed2 = new Computation(() -> computed() + ' bar');

		return new Task(activate -> {
			Observer.track(() -> {
				computed2.get().equals(value + ' foo bar');
				if (value == 'bar') activate(Ok(Nothing));
			});
			value = 'bar';
			signal.set(value);
		});
	}
}

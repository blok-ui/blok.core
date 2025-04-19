package blok.signal;

import blok.debug.Debug;
import blok.Scheduler;

enum abstract RuntimeStatus(Bool) to Bool {
	final Idle = false;
	final Notifying = true;
}

@:allow(blok.signal)
class Runtime {
	private static var instance:Null<Runtime> = null;

	public static function setCurrent(runtime:Runtime):Null<Runtime> {
		var prev = instance;
		instance = runtime;
		return prev;
	}

	public static function current():Runtime {
		if (instance == null) {
			instance = new Runtime(Scheduler.current().schedule);
		}
		return instance;
	}

	public final schedule:(effect:() -> Void)->Void;

	var status:RuntimeStatus = Idle;
	var epoch:Int = 1;
	var currentConsumerNode:Null<ReactiveNode> = null;

	public function new(schedule) {
		this.schedule = schedule;
	}

	public function incrementEpoch() {
		epoch++;
	}

	public function setCurrentConsumer(consumer:Null<ReactiveNode>):Null<ReactiveNode> {
		var prev = currentConsumerNode;
		currentConsumerNode = consumer;
		return prev;
	}

	public function currentConsumer() {
		return currentConsumerNode;
	}

	public inline function assertNotNotifying() {
		assert(status != Notifying, 'Cannot add producers while the runtime is Notifying');
	}

	public function whileNotifying(effect:() -> Void, ?finish:() -> Void) {
		var prev = status;
		status = Notifying;
		try effect() catch (e) {
			status = prev;
			if (finish != null) finish();
			throw e;
		}
		status = prev;
		if (finish != null) finish();
	}

	public inline function untrack<T>(handler:() -> T):T {
		return track(null, handler);
	}

	public function track<T>(node:ReactiveNode, handler:() -> T, ?finish:() -> Void):T {
		var prev = setCurrentConsumer(node);
		var value = try handler() catch (e) {
			if (finish != null) finish();
			setCurrentConsumer(prev);
			throw e;
		}

		if (finish != null) finish();
		setCurrentConsumer(prev);
		return value;
	}
}

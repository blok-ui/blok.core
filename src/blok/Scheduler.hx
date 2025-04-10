package blok;

class Scheduler {
	private static var instance:Null<Scheduler> = null;

	public static function setCurrent(scheduler:Scheduler):Scheduler {
		var prev = instance;
		instance = scheduler;
		return prev;
	}

	public static function current():Scheduler {
		if (instance == null) {
			instance = new Scheduler();
		}
		return instance;
	}

	#if js
	static final hasRaf:Bool = js.Syntax.code("typeof window != 'undefined' && 'requestAnimationFrame' in window");
	#end

	var onUpdate:Null<Array<() -> Void>> = null;

	public function new() {}

	public function schedule(effect:() -> Void) {
		if (onUpdate == null) {
			onUpdate = [];
			onUpdate.push(effect);
			later(doUpdate);
		} else {
			onUpdate.push(effect);
		}
	}

	public function scheduleNextTime(effect:() -> Void) {
		schedule(() -> schedule(effect));
	}

	function later(exec:() -> Void) {
		#if (js && nodejs)
		js.Node.process.nextTick(exec);
		#elseif js
		// @todo: Investigate queueMicrotask.
		if (hasRaf)
			js.Syntax.code('window.requestAnimationFrame({0})', _ -> exec());
		else
			haxe.Timer.delay(() -> exec(), 10);
		#else
		haxe.Timer.delay(() -> exec(), 10);
		#end
	}

	function doUpdate() {
		if (onUpdate == null) return;

		var currentUpdates = onUpdate.copy();
		onUpdate = null;

		for (u in currentUpdates) u();
	}
}

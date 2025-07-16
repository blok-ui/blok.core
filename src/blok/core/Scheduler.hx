package blok.core;

class Scheduler {
	private static var instance:Null<Scheduler> = null;

	public static function setCurrent(scheduler:Scheduler):Scheduler {
		var prev = instance;
		instance = scheduler;
		return prev;
	}

	public static function current():Scheduler {
		if (instance == null) {
			instance = new Scheduler(exec -> {
				#if (js && nodejs)
				js.Node.process.nextTick(exec);
				#elseif js
				// @todo: Investigate queueMicrotask.
				if (js.Syntax.code("typeof window != 'undefined' && 'requestAnimationFrame' in window"))
					js.Syntax.code('window.requestAnimationFrame({0})', _ -> exec());
				else
					haxe.Timer.delay(() -> exec(), 10);
				#else
				haxe.Timer.delay(() -> exec(), 10);
				#end
			});
		}
		return instance;
	}

	final adaptor:SchedulerAdaptor;

	var scheduled:Maybe<ScheduledEffects> = None;

	public function new(adaptor) {
		this.adaptor = adaptor;
	}

	public function schedule(effect:() -> Void) {
		switch scheduled {
			case Some(scheduled):
				scheduled.renders.push(effect);
			case None:
				scheduled = Some({
					renders: [effect],
					effects: []
				});
				adaptor(resolve);
		}
	}

	public function scheduleEffect(effect:() -> Void) {
		switch scheduled {
			case Some(scheduled):
				scheduled.effects.push(effect);
			case None:
				scheduled = Some({
					renders: [],
					effects: [effect]
				});
				adaptor(resolve);
		}
	}

	public function scheduleFuture():Future<Nothing> {
		return new Future(activate -> schedule(() -> activate(Nothing)));
	}

	public function scheduleFutureEffect():Future<Nothing> {
		return new Future(activate -> scheduleEffect(() -> activate(Nothing)));
	}

	function resolve() {
		var pending = switch scheduled {
			case Some(scheduled): scheduled;
			case None: return;
		}
		scheduled = None;

		for (effect in pending.renders) effect();
		for (effect in pending.effects) effect();
	}
}

typedef ScheduledEffects = {
	public final renders:Array<() -> Void>;
	public final effects:Array<() -> Void>;
}

typedef SchedulerAdaptor = (effect:() -> Void)->Void;

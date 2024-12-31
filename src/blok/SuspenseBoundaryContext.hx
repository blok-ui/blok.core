package blok;

import blok.Scheduler;
import blok.Context;

@:fallback(new SuspenseBoundaryContext())
class SuspenseBoundaryContext implements Context {
	public final onComplete = new Event();
	public final onSuspended = new Event();

	final scheduler:Scheduler;
	final suspendedBoundaries:Array<SuspenseBoundary> = [];

	public function new(?props:{
		?onComplete:() -> Void,
		?onSuspended:() -> Void,
		?scheduler:Scheduler
	}) {
		if (props?.onComplete != null) onComplete.add(props.onComplete);
		if (props?.onSuspended != null) onSuspended.add(props.onSuspended);

		scheduler = props?.scheduler ?? Scheduler.current();
		scheduler.schedule(() -> {
			if (suspendedBoundaries.length == 0) onComplete.dispatch();
		});
	}

	public function add(boundary:SuspenseBoundary) {
		if (suspendedBoundaries.contains(boundary)) return;
		if (suspendedBoundaries.length == 0) {
			onSuspended.dispatch();
		}
		suspendedBoundaries.push(boundary);
	}

	public function addErrored(boundary:SuspenseBoundary) {
		if (suspendedBoundaries.contains(boundary)) return;
		suspendedBoundaries.push(boundary);
	}

	public function remove(boundary:SuspenseBoundary) {
		if (!suspendedBoundaries.contains(boundary)) return;
		suspendedBoundaries.remove(boundary);
		if (suspendedBoundaries.length == 0) {
			onComplete.dispatch();
		}
	}

	public function dispose() {
		onComplete.cancel();
		onSuspended.cancel();
	}
}

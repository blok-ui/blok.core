package blok.suspense;

import blok.suspense.SuspenseBoundary;
import blok.ui.*;

/**
	Wrap a Component in a SuspenseBoundary/
**/
function inSuspense(child:Child, fallback:() -> Child) {
	return new SuspenseBoundaryModifier({
		child: child,
		fallback: fallback
	});
}

abstract SuspenseBoundaryModifier(SuspenseBoundaryProps) {
	public function new(props) {
		this = props;
	}

	public function onComplete(event) {
		this.onComplete = event;
		return abstract;
	}

	public function onSuspended(event) {
		this.onSuspended = event;
		return abstract;
	}

	@:to public function node():Child {
		return SuspenseBoundary.node(this);
	}
}

package blok;

import blok.SuspenseBoundary;

/**
	Wraps a component in an ErrorBoundary, which will catch all errors
	and pass them to `fallback`.
	```haxe
	blok.Scope.wrap(_ -> {
	  throw 'Some error';
	}).inErrorBoundary(e -> {
	  return blok.Text.node(e.message);
	});
	```
**/
function inErrorBoundary(child:Child, fallback:(e:haxe.Exception) -> Child) {
	return ErrorBoundary.node({
		child: child,
		fallback: fallback
	});
}

/**
	Wraps a component in a SuspenseBoundary.
**/
function inSuspense(child:Child, fallback:() -> Child) {
	return new SuspenseBoundaryModifier({
		child: child,
		fallback: fallback
	});
}

private abstract SuspenseBoundaryModifier(SuspenseBoundaryProps) {
	public function new(props:SuspenseBoundaryProps) {
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

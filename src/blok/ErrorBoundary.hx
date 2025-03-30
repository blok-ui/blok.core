package blok;

import haxe.Exception;

using blok.BoundaryTools;

enum ErrorBoundaryStatus {
	Ok;
	Caught(component:View, e:Exception);
}

// @todo: We need a way to "recover" from an error.
class ErrorBoundary extends Component implements Boundary {
	@:attribute final fallback:(component:View, e:Exception) -> Child;
	@:signal final status:ErrorBoundaryStatus = Ok;
	@:children @:attribute final child:Child;

	public function handle(component:View, object:Any) {
		if (object is Exception) {
			status.set(Caught(component, object));
			SuspenseBoundaryContext
				.maybeFrom(this)
				.inspect(context -> {
					// This ensures any SuspenseBoundaryContext will pause
					// and wait for this error handler to render before it triggers
					// `onComplete`.
					context.addErrored(this);
					getAdaptor().scheduleNextTime(() -> {
						if (!viewIsMounted()) return;
						context.remove(this);
					});
				});
			return;
		}
		this.tryToHandleWithBoundary(object);
	}

	function render() {
		return switch status() {
			case Ok:
				child;
			case Caught(c, e):
				fallback(c, e);
		}
	}
}

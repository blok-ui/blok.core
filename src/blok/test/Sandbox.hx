package blok.test;

import blok.core.Disposable;
import blok.engine.*;
import haxe.Exception;

using blok.Modifiers;

class Sandbox<Primitive> implements Disposable {
	public final onSuspended:Event = new Event();
	public final onComplete:Event<Root<Primitive>> = new Event<Root<Primitive>>();
	public final onError:Event<Root<Primitive>, Exception> = new Event<Root<Primitive>, Exception>();

	final root:Root<Primitive>;

	public function new(primitive:Primitive, adaptor:Adaptor, body:Child) {
		this.root = new Root(primitive, adaptor, body
			.inSuspense(() -> '...')
			.onSuspended(() -> onSuspended.dispatch())
			.onComplete(() -> onComplete.dispatch(root))
			.node()
			.inErrorBoundary(e -> {
				onError.dispatch(root, e);
				'ERROR ENCOUNTERED';
			})
		);
	}

	public function mount():Task<Root<Primitive>> {
		return new Task(activate -> {
			var handled = false;
			onComplete.addOnce(root -> {
				if (handled) return;
				handled = true;
				activate(Ok(root));
			});
			onError.addOnce((root, exception) -> {
				if (handled) return;
				handled = true;
				activate(Error(kit.Error.ofException(exception)));
			});
			root.mount()
				.inspectError(e -> {
					if (!handled) {
						handled = true;
						activate(Error(viewErrorToError(e)));
					}
				});
		});
	}

	public function update(body:Child):Task<Root<Primitive>> {
		return new Task(activate -> {
			var handled = false;
			var suspended = false;
			onSuspended.addOnce(() -> suspended = true);
			onComplete.addOnce(root -> {
				if (handled) return;
				handled = true;
				activate(Ok(root));
			});
			onError.addOnce((root, exception) -> {
				if (handled) return;
				handled = true;
				activate(Error(kit.Error.ofException(exception)));
			});
			root.root
				.update(None, body, root.adaptor.children(root.primitive))
				.inspect(_ -> {
					if (suspended == false && handled == false) {
						handled = true;
						activate(Ok(root));
					}
				})
				.inspectError(e -> {
					if (!handled) {
						handled = true;
						activate(Error(viewErrorToError(e)));
					}
				});
		});
	}

	function viewErrorToError(error:ViewError) {
		return switch error {
			case ViewAlreadyExists(view): new Error(InternalError, 'View already exists');
			case InsertionFailed(view, message): new Error(InternalError, 'Insertion failed');
			case UpdateFailed(view, message): new Error(InternalError, 'Update failed');
			case RemovalFailed(view, message): new Error(InternalError, 'Removal failed');
			case IncorrectNodeType(view, node): new Error(NotAcceptable, 'Incorrect node type');
			case HydrationMismatch(view, expected, actual): new Error(NotAcceptable, 'Hydration mismatch');
			case NoNodeFoundDuringHydration(view, expected): new Error(NotAcceptable, 'Hydration mismatch');
			case CausedException(view, exception): kit.Error.ofException(exception);
		}
	}

	public function dispose() {
		onSuspended.cancel();
		onComplete.cancel();
		onError.cancel();
		root.dispose();
	}
}

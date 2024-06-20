package blok.suspense;

import blok.core.*;
import blok.signal.Computation;
import blok.signal.Observer;
import blok.signal.Signal;

@:forward
abstract Resource<T, E = kit.Error>(ResourceObject<T, E>) from ResourceObject<T, E> to Disposable to DisposableItem {
	@:from
	public static function ofTask<T, E>(task:Task<T, E>):Resource<T, E> {
		return new DefaultResourceObject(() -> task);
	}

	public function new(fetch) {
		this = new DefaultResourceObject(fetch);
	}

	@:to
	public function toReadOnlySignal():ReadOnlySignal<T> {
		return this;
	}

	@:op(a())
	public inline function get() {
		return this.get();
	}
}

enum ResourceStatus<T, E = kit.Error> {
	Pending;
	Loading(task:Task<T, E>);
	Loaded(value:T);
	Error(e:E);
}

interface ResourceObject<T, E = kit.Error> extends Disposable {
	public final data:ReadOnlySignal<ResourceStatus<T, E>>;
	public final loading:ReadOnlySignal<Bool>;
	public function get():T;
	public function peek():T;
}

class DefaultResourceObject<T, E = kit.Error> implements ResourceObject<T, E> {
	public final data:Signal<ResourceStatus<T, E>>;
	public final loading:ReadOnlySignal<Bool>;

	final fetch:() -> Task<T, E> = null;
	final disposables:DisposableCollection = new DisposableCollection();

	var link:Null<Cancellable> = null;

	public function new(fetch) {
		var prevOwner = Owner.setCurrent(disposables);

		this.data = new Signal(Pending);
		this.loading = new Computation(() -> switch data() {
			case Loading(_) | Pending: true;
			default: false;
		});
		this.fetch = fetch;

		Owner.setCurrent(prevOwner);

		prevOwner?.addDisposable(this);
	}

	public function get():T {
		// Note: It's important we set up the Observer *before* the
		// signal is accessed for the first time. This will ensure
		// we don't trigger dependencies more than once.
		switch data.peek() {
			case Pending:
				Owner.with(disposables, () -> Observer.track(() -> {
					link?.cancel();

					var handled = false;
					var task = fetch();

					link = task.handle(result -> switch result {
						case Ok(value):
							handled = true;
							data.set(Loaded(value));
						case Error(error):
							handled = true;
							data.set(Error(error));
					});

					if (!handled) data.set(Loading(task));
				}));
			default:
		}

		return switch data() {
			case Pending:
				throw new BlokException('Data was not initialized');
			case Loaded(value):
				value;
			case Loading(task):
				throw new SuspenseException(task);
			case Error(e):
				throw e;
		}
	}

	public function peek():T {
		// @todo: how should we handle this?
		throw 'Not allowed on Resources';
	}

	public function dispose() {
		link?.cancel();
		link = null;
		disposables.dispose();
	}
}

package blok.suspense;

import blok.core.*;
import blok.signal.Computation;
import blok.signal.Graph;
import blok.signal.Observer;
import blok.signal.Signal;

// @todo: This is super awkward to use with Blok's VNode based
// system. We may need some kind of hooks-like system, or we'll 
// have to get it from context somehow.
@:forward
abstract Resource<T, E = kit.Error>(ResourceObject<T, E>) from ResourceObject<T, E> {
  @:from
  public static function ofTask<T, E>(task:Task<T, E>):Resource<T, E> {
    return new DefaultResourceObject(() -> task);
  }

  public function new(fetch) {
    this = new DefaultResourceObject(fetch);
  }

  @:op(a())
  public inline function get() {
    return this.get();
  }
}

enum ResourceStatus<T, E = kit.Error> {
  Loading;
  Loaded(value:T);
  Error(e:E);
}

interface ResourceObject<T, E = kit.Error> extends Disposable {
  public final data:ReadonlySignal<ResourceStatus<T, E>>;
  public final loading:ReadonlySignal<Bool>;
  public function get():T;
}

class DefaultResourceObject<T, E = kit.Error> implements ResourceObject<T, E> {
  public final data:Signal<ResourceStatus<T, E>>;
  public final loading:ReadonlySignal<Bool>;

  final fetch:Computation<Task<T, E>>;
  final disposables:DisposableCollection = new DisposableCollection();
  
  var link:Null<Cancellable> = null;

  public function new(fetch:()->Task<T, E>) {
    var prevOwner = setCurrentOwner(Some(disposables));

    this.data = new Signal(Loading);
    this.loading = this.data.map(status -> status == Loading);
    this.fetch = new Computation(fetch);
    
    Observer.track(() -> {
      link?.cancel();

      data.set(Loading);

      link = fetch().handle(result -> switch result {
        case Ok(value): data.set(Loaded(value));
        case Error(error): data.set(Error(error));
      });
    });

    setCurrentOwner(prevOwner);
  }

  public function get():T {
    return switch data() {
      case Loaded(value): value;
      case Loading: throw new SuspenseException(fetch());
      case Error(e): throw e;
    }
  }

  public function dispose() {
    link?.cancel();
    link = null;
    disposables.dispose();
  }
}
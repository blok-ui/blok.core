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
  
  final fetch:()->Task<T, E> = null;
  final disposables:DisposableCollection = new DisposableCollection();
  final currentFetch:Signal<Maybe<Task<T, E>>> = new Signal(None);

  var link:Null<Cancellable> = null;
  var first:Bool = true;

  public function new(fetch:()->Task<T, E>) {
    var prevOwner = setCurrentOwner(Some(disposables));

    this.data = new Signal(Loading);
    this.loading = this.data.map(status -> status == Loading);
    this.fetch = fetch;
    
    Observer.track(() -> {
      var handled = false;
      switch currentFetch() {
        case None:
          link?.cancel();
          link = null;
        case Some(task):
          link?.cancel();
          link = task.handle(result -> switch result {
            case Ok(value): 
              handled = true;
              data.set(Loaded(value));
            case Error(error): 
              handled = true;
              data.set(Error(error));
          });
      }
      if (!handled) data.set(Loading);
    });

    setCurrentOwner(prevOwner);
  }

  public function get():T {
    if (first) {
      first = false;
      withOwner(disposables, () -> Observer.track(() -> {
        currentFetch.set(Some(fetch()));
      }));
    }

    return switch data() {
      case Loaded(value):
        value;
      case Loading:
        throw new SuspenseException(currentFetch.peek().unwrap());
      case Error(e): 
        throw e;
    }
  }

  public function dispose() {
    link?.cancel();
    link = null;
    disposables.dispose();
  }
}

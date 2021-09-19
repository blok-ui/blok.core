package blok;

typedef ObservableType<T> = {
  public function getObservable():Observable<T>;
}

typedef ObservableOptions = {
  /**
    If `true`, the Observer will NOT be run immediately,
    and will only be called when the observer is next notified.
  **/
  public var defer:Bool;
}

/**
  Allows either `Observable<T>` or `ObservableType<T>` to be
  used interchangeably.
**/
@:forward(observe)
abstract ObservableTarget<T>(Observable<T>) from Observable<T> to Observable<T> {
  @:from public static inline function ofObservableType<T>(obs:ObservableType<T>) {
    return new ObservableTarget(obs.getObservable());
  }

  public inline function new(obs) {
    this = obs;
  }
}

typedef ObservableComparitor<T> = (a:T, b:T)->Bool; 

@:allow(blok.Observable)
private class Observer<T> implements Disposable {
  final listener:(value:T)->Void;
  
  var isDisposed:Bool = false;
  var observable:Null<Observable<T>>;
  var next:Null<Observer<T>>;

  public function new(observable:Observable<T>, listener) {
    this.listener = listener;
    this.observable = observable;
  }

  public function handle(value:T) {
    listener(value);
  }

  final public function dispose() {
    if (isDisposed) return;
    if (observable != null) observable.remove(this);
  }

  function cleanupOnRemoved() {
    if (isDisposed) return;
    isDisposed = true;
    if (observable != null) {
      observable = null;
      next = null;
    }
  }
}

@:allow(blok.Observable)
private class LinkedObserver<T, R> extends Observer<T> {
  final linkedObservable:Observable<R>;

  public function new(
    parent:Observable<T>,
    linked:Observable<R>,
    transform:(value:T)->R
  ) {
    linkedObservable = linked;
    linkedObservable.link = this;
    super(parent, value -> linkedObservable.update(transform(value)));
  }

  public function getObservable():Observable<R> {
    return linkedObservable;
  }
  
  override function cleanupOnRemoved() {
    super.cleanupOnRemoved();
    linkedObservable.link = null;
    linkedObservable.dispose();
  }
}

enum abstract HandleableObserverStatus(Bool) {
  var Handled = true;
  var Pending = false;
}

private class ConditionalObserver<T> extends Observer<T> {
  public function new(observable, listener:(value:T)->HandleableObserverStatus) {
    super(observable, value -> {
      switch (listener(value)) {
        case Handled: dispose();
        case Pending: // noop
      }
    });
  }
}

@:allow(blok.Observer)
@:allow(blok.SuspendableData)
class Observable<T> implements Disposable {
  static var uid:Int = 0;

  final comparator:ObservableComparitor<T>;

  var notifying:Bool = false;
  var value:T;
  var head:Null<Observer<T>>;
  var toAddHead:Null<Observer<T>>;
  var link:Null<Disposable> = null;

  public var length(get, never):Int;
  function get_length() {
    var len = 0;
    var current = head;
    while (current != null) {
      len++;
      current = current.next;
    }
    return len;
  }

  public function new(value, ?comparator) {
    this.value = value;
    this.comparator = comparator == null ? (a, b) -> a != b : comparator;
  }

  /**
    Observe this Observer. The provided listener will update every time the Observable
    is notified unless you call `dispose` on the returned Disposable (or if the 
    Observable itself is disposed). Use `observeConditionally` if you need a 
    way to tell the observer to stop observing internally.
  **/
  public function observe(listener:(value:T)->Void, ?options:ObservableOptions):Disposable {
    if (options == null) options = { defer: false };

    var observer = new Observer(this, listener);
    addObserver(observer, options);
    
    return observer;
  }

  /**
    Observe the next result and don't fire immediately. Useful in situations
    where you want the Observable to act more like a signal.
  **/
  public inline function observeNext(listener) {
    return observe(listener, { defer: true });
  }

  /**
    Works the same as normal `observe`, but requires you to return either
    `Handled` or `Pending`. If the observation is `Handled`, the Observer
    will be removed.
  **/
  public function handle(listener:(value:T)->HandleableObserverStatus, ?options:ObservableOptions):Disposable {
    if (options == null) options = { defer: false };

    var observer = new ConditionalObserver(this, listener);
    addObserver(observer, options);
    
    return observer;
  }

  public function handleNext(listener) {
    return handle(listener, { defer: true });
  }
  
  function addObserver(observer:Observer<T>, options:ObservableOptions) {
    if (notifying) {
      observer.next = toAddHead;
      toAddHead = observer;
    } else {
      observer.next = head;
      head = observer;
    }

    if (!options.defer) observer.handle(value);
  }

  /**
    Notify all listeners with the current value.
  **/
  public function notify() {
    if (notifying) return;

    notifying = true;
    
    var current = head;
    
    while (current != null) {
      current.handle(this.value);
      current = current.next;
    }

    notifying = false;
    
    if (toAddHead != null) {
      if (current != null) {
        current.next = toAddHead;
      } else {
        head = toAddHead;
      }
      toAddHead = null;
    }
  }

  /**
    Update the current value and then notify all listeners.

    If the comparator does not detect a change in the value, listeners
    will NOT be notified. If you want to force notification, use `notify()`
    instead.
  **/
  public function update(value:T):Void {
    if (comparator != null && !comparator(this.value, value)) return;
    this.value = value;
    notify();
  }
  
  public function remove(observer:Observer<T>):Void {
    inline function iterate(head:Null<Observer<T>>) {
      var current = head;
      while (current != null) {
        if (current.next == observer) {
          current.next = observer.next;
          break;
        }
        current = current.next;
      }
    }

    if (head == observer) {
      head = observer.next;
      return;
    }

    iterate(head);
    iterate(toAddHead);

    observer.cleanupOnRemoved();
  }

  public function dispose():Void {
    inline function iterate(head:Null<Observer<T>>) {
      var current = head;
      while (current != null) {
        var next = current.next;
        current.dispose();
        current = next;
      }
    }

    iterate(head);
    iterate(toAddHead);

    head = null;
    toAddHead = null;

    // Clean things up if this is being used by a LinkedObserver.
    if (link != null) {
      link.dispose();
      link = null;
    }
  }

  /**
    Map this Observable into another.
  **/
  public inline function map<R>(transform:(value:T)->R, ?comparator):Observable<R> {
    var observer = new LinkedObserver(
      this, 
      new Observable(transform(value), comparator),
      transform
    );
    addObserver(observer, { defer: false });
    return observer.getObservable();
  }

  /**
    Map this Observable into a VNode.
  **/
  public inline function mapToVNode<Node>(build) {
    return ObservableSubscriber.node({
      target: this,
      build: build
    });
  }
}

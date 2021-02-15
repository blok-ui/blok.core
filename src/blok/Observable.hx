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
class Observer<T> implements Disposable {
  final listener:(value:T)->Void;
  
  var isDisposed:Bool = false;
  var observable:Null<Observable<T>>;
  var next:Null<Observer<T>>;

  public function new(observable:Observable<T>, listener) {
    this.listener = listener;
    this.observable = observable;
  }

  public inline function handle(value:T) {
    listener(value);
  }

  final public function dispose() {
    if (isDisposed) return;
    if (observable != null) observable.remove(this);
  }

  function onRemoved() {
    if (isDisposed) return;
    isDisposed = true;
    if (observable != null) {
      observable = null;
      next = null;
    }
  }
}

@:allow(blok.Observable)
class LinkedObserver<T, R> extends Observer<T> {
  final linkedObservable:Observable<R>;

  public function new(
    parent:Observable<T>,
    linked:Observable<R>,
    transform:(value:T)->R
  ) {
    linkedObservable = linked;
    super(parent, function (value) linkedObservable.update(transform(value)));
  }

  public function getObservable():Observable<R> {
    return linkedObservable;
  }
  
  override function onRemoved() {
    super.onRemoved();
    linkedObservable.dispose();
  }
}

class Observable<T> implements Disposable {
  static var uid:Int = 0;

  final comparator:Null<ObservableComparitor<T>>;

  var notifying:Bool = false;
  var value:T;
  var head:Null<Observer<T>>;
  var toAddHead:Null<Observer<T>>;

  public function new(value, ?comparator) {
    this.value = value;
    this.comparator = comparator;
  }

  public function observe(listener:(value:T)->Void, ?options:ObservableOptions):Observer<T> {
    if (options == null) options = { defer: false };

    var observer = new Observer(this, listener);
    addObserver(observer, options);
    
    return observer;
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

  public function update(value:T):Void {
    if (comparator != null && !comparator(this.value, value)) return;
    
    notifying = true;

    this.value = value;
    
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

    observer.onRemoved();
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
  }

  /**
    Select a value from the Observable and only update when that value changes.

    Otherwise works the same as `map`.
  **/
  public function select<R>(selector:(value:T)->R) {
    var observer = new LinkedObserver(
      this, 
      new Observable(selector(value), (a, b) -> a != b),
      selector
    );
    addObserver(observer, { defer: false });
    return observer.getObservable();
  }

  /**
    Map this Observable into another.
  **/
  public inline function map<R>(transform:(value:T)->R):Observable<R> {
    var observer = new LinkedObserver(
      this, 
      new Observable(transform(value)),
      transform
    );
    addObserver(observer, { defer: false });
    return observer.getObservable();
  }

  public inline function mapToVNode<Node>(build) {
    return ObservableSubscriber.observe(this, build);
  }
}

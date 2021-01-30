package blok;

import haxe.Constraints.Function;

/**
  A generic signal. Can have as many params as you'd like.

  Implementation from: https://gist.github.com/nadako/b086569b9fffb759a1b5
**/
@:genericBuild(blok.SignalBuilder.build())
class Signal<Rest> {}

/* abstract */ class SignalBase<T:Function> implements Disposable {
  public var isDisposed(default, null):Bool = false;
  var dispatching:Bool = false;
  var head:SignalSubscription<T>;
  var tail:SignalSubscription<T>;
  var toAddHead:SignalSubscription<T>;
  var toAddTail:SignalSubscription<T>;

  public function new() {}

  public function add(listener:T, once:Bool = false):Disposable {
    if (isDisposed) {
      throw 'Cannot add a listener to a disposed signal';
    }
      
    var sub = new SignalSubscription(this, listener, once);

    if (dispatching) {
      if (toAddHead == null) {
        toAddHead = toAddTail = sub;
      } else {
        toAddHead.next = sub;
        sub.previous = toAddTail;
        toAddTail = sub;
      }
    } else {
      if (head == null) {
        head = tail = sub;
      } else {
        tail.next = sub;
        sub.previous = tail;
        tail = sub;
      }
    }

    return sub;
  }

  public inline function addOnce(listener:T) {
    return add(listener, true);
  }

  public function dispose() {
    clear();
    isDisposed = true;
  }

  public function clear() {
    var sub = head;

    while (sub != null) {
      var cur = sub;
      sub = cur.next;
      cur.signal = null;
      cur.previous = null;
      cur.next = null;
    }

    head = null;
    tail = null;
    toAddHead = null;
    toAddTail = null;
  }

  public function remove(sub:SignalSubscription<T>) {
    if (head == sub)
      head = head.next;
    if (tail == sub)
      tail = tail.previous;
    if (toAddHead == sub)
      toAddHead = toAddHead.next;
    if (toAddTail == sub)
      toAddTail = toAddTail.previous;
    if (sub.previous != null)
      sub.previous.next = sub.next;
    if (sub.next != null)
      sub.next.previous = sub.previous;
    sub.signal = null;
  }

  inline function startDispatch() {
    dispatching = true;
  }

  inline function endDispatch() {
    dispatching = false;
    if (toAddHead != null) {
      if (head == null) {
        head = toAddHead;
        tail = toAddTail;
      } else {
        tail.next = toAddHead;
        toAddHead.previous = tail;
        tail = toAddTail;
      }
      toAddHead = toAddTail = null;
    }
  }
}

@:allow(blok.SignalBase)
class SignalSubscription<T:Function> implements Disposable {
  final listener:T;
  final once:Bool;

  var signal:SignalBase<T>;
  var previous:SignalSubscription<T>;
  var next:SignalSubscription<T>;

  function new(signal, listener, once) {
    this.signal = signal;
    this.listener = listener;
    this.once = once;
  }

  public function dispose():Void {
    if (signal != null) {
      signal.remove(this);
      signal = null;
    }
  }
}

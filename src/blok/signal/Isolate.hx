package blok.signal;

import blok.signal.Graph;
import blok.core.*;

/**
  An Isolate wraps a given scope and disposes any signals/observers/etc.
  that are used within it every time it's called.
  
  This is used, for example, inside Component `render` methods to ensure
  that any observers or computations created there are properly removed
  when the component renders again.
**/
@:forward
abstract Isolate<T>(IsolateImpl<T>) to Disposable {
  @:from 
  public static inline function ofFunction<T>(scope:()->T) {
    return new Isolate(scope);
  }

  public inline function new(scope) {
    this = new IsolateImpl(scope);
  }

  @:op(a())
  public inline function get():T {
    return this.get();
  }
}

class IsolateImpl<T> implements Disposable {
  final scope:()->T;

  var owner:Null<DisposableCollection>;

  public function new(scope) {
    this.scope = scope;
  }

  public function get():T {
    cleanup();
    owner = new DisposableCollection();
    return withOwnedValue(owner, scope);
  }

  public function cleanup() {
    owner?.dispose();
    owner = null;
  }

  public function dispose() {
    owner?.dispose();
    owner = null;
  }
}

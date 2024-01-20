package blok.signal;

import blok.core.*;
import blok.debug.Debug;
import blok.signal.Signal;
import haxe.Exception;

@:forward
abstract Computation<T>(ComputationObject<T>) from ComputationObject<T> to Disposable {
  /**
    Eager Computations will always recompute, even if they don't
    have any consumers of their own.
  **/
  public static function eager<T>(value, ?equal):Computation<T> {
    return new ComputationObject(value, equal, true);
  }

  /**
    Lazy computations will only recompute if they have consumers.

    This is the default behavior for Computations and is generally
    recommended.
  **/
  public static function lazy<T>(value, ?equal):Computation<T> {
    return new ComputationObject(value, equal, false);
  }

  public inline function new(value, ?equal) {
    this = new ComputationObject(value, equal);
  }

  @:op(a())
  public inline function get() {
    return this.get();
  }

  @:to
  public inline function asReadOnlySignal():ReadOnlySignal<T> {
    return this;
  }

  public inline function map<R>(transform:(value:T)->R):ReadOnlySignal<R> {
    return new Computation(() -> transform(get()));
  }
}

enum ComputationStatus<T> {
  Uninitialized;
  Computing;
  Computed(value:T);
  Errored(e:Exception);
}

class ComputationObject<T> implements Disposable {
  final factory:()->T;
  final equals:(a:T, b:T)->Bool;
  final node:ReactiveNode;
  
  var status:ComputationStatus<T> = Uninitialized;

  public function new(factory, ?equals, ?alwaysLive) {
    this.factory = factory;
    this.equals = equals ?? (a, b) -> a == b;
    this.node = new ReactiveNode(
      Runtime.current(),
      _ -> compute(),
      alwaysLive
    );
  }

  public function get():T {
    compute();
    node.accessed();
    return resolveValue();
  }

  public function peek():T {
    compute();
    return resolveValue();
  }

  public function dispose() {
    node.dispose();
  }

  function resolveValue() {
    return switch status {
      case Uninitialized: 
        error('No value computed');
      case Errored(e):
        throw e;
      case Computing:
        error('Cycle detected');
      case Computed(value):
        value;
    };
  }

  function compute() {
    switch status {
      case Uninitialized:
        var value:Null<T> = null;

        status = Computing;
        
        try node.useAsCurrentConsumer(() -> value = factory()) catch (e) {
          status = Errored(e);
        }
        
        switch status {
          case Errored(_):
          default: 
            status = Computed(value);
        }
      case Computed(prevValue) if (node.status == Invalid):
        // Eagerly recompute a value on access even if node validation
        // is still scheduled.
        var value:T = prevValue;

        status = Computing;
        node.status = Valid;

        try node.useAsCurrentConsumer(() -> {
          var newValue = factory();
    
          if (equals(prevValue, newValue)) return;
    
          value = newValue;
          node.version++;
        }) catch (e) {
          status = Errored(e);
        }

        switch status {
          case Errored(_):
          default: 
            status = Computed(value);
        }
      default:
    }
  }
}

package blok.signal;

import blok.debug.Debug.warn;
import blok.core.Scheduler.getCurrentScheduler;
import blok.core.*;

using Kit;
using Lambda;

// @todo: Is tracking versions actually doing anything for
// us? Test this.
abstract NodeVersion(Int) {
  public inline function new() {
    this = 0;
  }

  public inline function increment() {
    this++;
  }

  @:to inline function unwrap():Int {
    return this;
  }

  public inline function compare(other:NodeVersion) {
    return this >= other.unwrap();
  }
}

@:allow(blok.signal)
interface Node extends Disposable {
  public final id:UniqueId;
  public function isInactive():Bool;
  public function getVersion():NodeVersion;
}

@:allow(blok.signal)
interface ProducerNode extends Node {
  public function notify():Void;
  public function bindConsumer(consumer:ConsumerNode):Void;
  public function unbindConsumer(consumer:ConsumerNode):Void;
}

@:allow(blok.signal)
interface ConsumerNode extends Node {
  public function invalidate():Void;
  public function validate():Void;
  public function pollProducers():Bool;
  public function bindProducer(node:ProducerNode):Void;
  public function unbindProducer(node:ProducerNode):Void;
}

private var currentOwner:Maybe<DisposableHost> = None;
private var currentConsumer:Maybe<ConsumerNode> = None;
private final pending:List<ConsumerNode> = new List();
private var depth:Int = 0;

function withOwner(owner:DisposableHost, cb:()->Void) {
  var prev = setCurrentOwner(Some(owner));
  try cb() catch (e) {
    setCurrentOwner(prev);
    throw e;
  }
  setCurrentOwner(prev);
}

function withOwnedValue<T>(owner:DisposableHost, cb:()->T) {
  var prev = setCurrentOwner(Some(owner));
  var value = try cb() catch (e) {
    setCurrentOwner(prev);
    throw e;
  }
  setCurrentOwner(prev);
  return value;
}

inline function getCurrentOwner() {
  return currentOwner;
}

function setCurrentOwner(owner:Maybe<DisposableHost>) {
  var prev = currentOwner;
  currentOwner = owner;
  return prev;
}

function withConsumer(consumer:ConsumerNode, cb:()->Void) {
  var prev = setCurrentConsumer(Some(consumer));
  try cb() catch (e) {
    setCurrentConsumer(prev);
    throw e;
  }
  setCurrentConsumer(prev);
}

inline function getCurrentConsumer() {
  return currentConsumer;
}

function setCurrentConsumer(consumer:Maybe<ConsumerNode>) {
  var prev = currentConsumer;
  currentConsumer = consumer;
  return prev;
}

function enqueueConsumer(node:ConsumerNode) {
  if (!pending.has(node)) pending.add(node);
  scheduleValidation();
}

function dequeueConsumer(node:ConsumerNode) {
  pending.remove(node);
}

var scheduled:Bool = false;

function scheduleValidation() {
  if (depth > 0) return;
  if (scheduled) return;
  switch getCurrentScheduler() {
    case Some(scheduler):
      scheduled = true; 
      scheduler.schedule(() -> {
        scheduled = false;
        validateConsumers();
      });
    case None: 
      warn('Using signals without a scheduler can result in strange behavior');
      validateConsumers();
  }
}

private function validateConsumers() {
  for (consumer in pending) {
    pending.remove(consumer);
    consumer.validate();
  }
}

function batch(compute:()->Void) {
  depth++;
  compute();
  depth--;
  scheduleValidation();
}

function untrack(compute:()->Void) {
  var prev = setCurrentConsumer(None);
  compute();
  setCurrentConsumer(prev);
}

function untrackValue<T>(compute:()->T) {
  var prev = setCurrentConsumer(None);
  var value = compute();
  setCurrentConsumer(prev);
  return value;
}

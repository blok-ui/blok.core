package blok.core;

class Scheduler {
  #if js
  static final hasRaf:Bool = js.Syntax.code("typeof window != 'undefined' && 'requestAnimationFrame' in window");
  #end

  var onUpdate:Null<Array<()->Void>> = null;

  public function new() {}

  public function schedule(item) {
    if (onUpdate == null) {
      onUpdate = [];
      onUpdate.push(item);
      later(doUpdate);
    } else {
      onUpdate.push(item);
    }
  }

  function later(exec:()->Void) {
    #if (js && nodejs)
    js.Node.process.nextTick(exec);
    #elseif js
    if (hasRaf)
      js.Syntax.code('window.requestAnimationFrame({0})', _ -> exec());
    else
      haxe.Timer.delay(() -> exec(), 10);
    #else
    haxe.Timer.delay(() -> exec(), 10);
    #end
  }
  
  function doUpdate() {
    if (onUpdate == null) return;

    var currentUpdates = onUpdate.copy();
    onUpdate = null;    
    
    for (u in currentUpdates) u();
  }
}

private var currentScheduler:Maybe<Scheduler> = Some(new Scheduler());

function setCurrentScheduler(scheduler:Maybe<Scheduler>) {
  var prev = currentScheduler;
  currentScheduler = scheduler;
  return prev;
}

function getCurrentScheduler() {
  return currentScheduler;
}

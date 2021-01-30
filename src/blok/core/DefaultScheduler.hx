package blok.core;

class DefaultScheduler implements Scheduler {
  #if js
    static final hasRaf:Bool = js.Syntax.code("typeof window != 'undefined' && 'requestAnimationFrame' in window");
  #end

  var queue:Signal<Void> = null;

  public function new() {}

  public function schedule(item) {
    if (queue == null) {
      queue = new Signal();
      queue.addOnce(item);
      later(run);
    } else {
      queue.addOnce(item);
    }
  }

  function later(exec:()->Void) {
    #if js
    if (hasRaf)
      js.Syntax.code('window.requestAnimationFrame({0})', _ -> exec());
    else
    #end
    haxe.Timer.delay(() -> exec(), 10);
  }
  
  function run() {
    if (queue == null) return;

    var error = null;
    var currentQueue = queue;
    queue = null;
    
    currentQueue.dispatch();
    
    if (error != null) throw error;
  }
}

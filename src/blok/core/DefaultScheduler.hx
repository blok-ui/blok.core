package blok.core;

class DefaultScheduler implements Scheduler {
  var queue:Array<()->Void> = null;

  public function new() {}

  public function schedule(item) {
    if (queue == null) {
      queue = [ item ];
      later(run);
    } else {
      queue.push(item);
    }
  }

  function later(fn:()->Void) {
    var impl:(fn:()->Void)->Void = fn -> haxe.Timer.delay(fn, 10);
    #if js
    impl = try {
        if (js.Browser.window.requestAnimationFrame != null)
          fn -> js.Browser.window.requestAnimationFrame(cast fn);
        else
          impl;
      } catch (e:Dynamic) {
        impl;
      }
    #end
    impl(fn);
  }
  
  function run() {
    if (queue == null) return;

    var error = null;
    var currentQueue = queue;
    queue = null;

    for (item in currentQueue) 
      try item() catch (e:haxe.Exception) error = e;
    
    if (error != null) throw error;
  }
}

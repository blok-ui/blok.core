package blok.html.client;

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
    #if js
    if (hasRaf)
      js.Syntax.code('window.requestAnimationFrame({0})', _ -> exec());
    else
    #end
    haxe.Timer.delay(() -> exec(), 10);
  }
  
  function doUpdate() {
    if (onUpdate == null) return;

    var currentUpdates = onUpdate.copy();
    onUpdate = null;    
    
    for (u in currentUpdates) u();
  }
}

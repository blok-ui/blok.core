package blok.boundary;

import haxe.Exception;
import blok.ui.*;

using blok.boundary.BoundaryTools;

class ErrorBoundary extends Component implements Boundary {
  @:constant final child:Child;
  @:constant final fallback:(component:ComponentBase, e:Exception, recover:()->Void)->Child;
  @:signal final status:ErrorBoundaryStatus = Ok;

  public function handle(component:ComponentBase, object:Any) {
    if (object is Exception) {
      status.set(Caught(component, object));
      return;
    }
    this.tryToHandleWithBoundary(object);
  }

  function recover() {
    status.set(Ok);
  }

  function render() {
    return switch status() {
      case Ok: child;
      case Caught(c, e): fallback(c, e, recover);
    }
  }
}

enum ErrorBoundaryStatus {
  Ok;
  Caught(component:ComponentBase, e:Exception);
}

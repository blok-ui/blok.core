package blok.boundary;

import haxe.Exception;
import blok.ui.*;

using blok.boundary.BoundaryTools;

enum ErrorBoundaryStatus {
  Ok;
  Caught(component:ComponentBase, e:Exception);
}

class ErrorBoundary extends Component implements Boundary {
  @:attribute final child:Child;
  @:attribute final fallback:(component:ComponentBase, e:Exception)->Child;
  @:signal final status:ErrorBoundaryStatus = Ok;

  public function handle(component:ComponentBase, object:Any) {
    if (object is Exception) {
      status.set(Caught(component, object));
      return;
    }
    this.tryToHandleWithBoundary(object);
  }

  function render() {
    return switch status() {
      case Ok: child;
      case Caught(c, e): fallback(c, e);
    }
  }
}

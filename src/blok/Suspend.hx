package blok;

import haxe.Exception;
import blok.exception.WrappedException;

typedef Resume = ()->Void;

enum abstract SuspendStatus(Bool) {
  var Suspended = true;
  var Complete = false;
}

@:allow(blok)
@service(fallback = new Suspend())
class Suspend implements Service implements Disposable {
  public inline static function await(build, fallback) {
    return SuspendablePoint.node({ build: build, fallback: fallback });
  }

  public inline static function suspend(handler):VNode {
    throw new SuspensionRequest(handler);
  }

  public inline static function isolate(build) {
    return Provider.provide(new Suspend(), build);
  }

  public final status:Observable<SuspendStatus>;
  final suspendedPoints:Map<SuspendablePoint, SuspensionRequest> = [];

  public function new() {
    status = new Observable(Complete);
  }

  function addPoint(
    point:SuspendablePoint,
    request:SuspensionRequest,
    platform:Platform
  ) {
    removePoint(point);
    suspendedPoints.set(point, request);
    status.update(Suspended);
    platform.scheduler.schedule(() -> {
      request.whenResumed(() -> point.invalidateWidget());
    });
  }

  function hasPoint(point:SuspendablePoint) {
    return suspendedPoints.exists(point);
  }

  function removePoint(point:SuspendablePoint) {
    if (suspendedPoints.exists(point)) {
      suspendedPoints.get(point).dispose();
      suspendedPoints.remove(point);
    }
  }

  function markComplete(point:SuspendablePoint, platform:Platform) {
    if (suspendedPoints.exists(point)) {
      suspendedPoints.remove(point);
      platform.scheduler.schedule(() -> {
        var remaining = [ for (key in suspendedPoints.keys()) key ].length;
        if (remaining == 0) status.update(Complete);
      });
    }
  }

  public function dispose() {
    status.dispose();
    for (_ => request in suspendedPoints) request.dispose();
    suspendedPoints.clear();
  }
}

class SuspensionRequest extends Exception implements Disposable {
  public final handler:(resume:Resume)->Void;
  public var resume:Null<Resume>;

  public function new(handler) {
    super('A suspension was unhandled');
    this.handler = handler;
  }

  public function whenResumed(resume:Resume) {
    this.resume = resume;
    handler(() -> {
      if (resume != null) resume();
    });
  }

  public function dispose() {
    resume = null;
  }
}

private class SuspendablePoint extends Component {
  @prop var build:()->VNodeResult;
  @prop var fallback:()->VNodeResult;
  @use var suspend:Suspend;
  var isReady:Bool = true;

  @effect
  function maybeNotify() {
    if (isReady && suspend.hasPoint(this)) {
      suspend.markComplete(this, getPlatform());
    }
    isReady = true;
  }

  @dispose
  function removeHandlers() {
    if (suspend.hasPoint(this)) suspend.removePoint(this);
  }

  override function componentDidCatch(exception:Exception):VNodeResult {
    return switch Std.downcast(exception, WrappedException) {
      case null: 
        super.componentDidCatch(exception);
      case wrapped: switch Std.downcast(wrapped.target, SuspensionRequest) {
        case null: 
          super.componentDidCatch(exception);
        case request:
          isReady = false;
          suspend.addPoint(this, request, getPlatform());
          fallback();
      }
    }
  }

  function render() {
    return build();
  }
}

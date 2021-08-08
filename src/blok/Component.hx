package blok;

import haxe.Exception;
import blok.exception.BlokException;
import blok.exception.WrappedException;

@:autoBuild(blok.ComponentBuilder.build())
abstract class Component extends Widget {
  var __currentRevision:Int = 0;
  var __lastRevision:Int = 0;
  var __manager:ConcreteManager = null;

  abstract public function updateComponentProperties(props:Dynamic):Void;
  
  abstract function render():VNodeResult;

  public function componentDidCatch(exception:Exception):VNodeResult {
    throw exception;
    return [];
  }

  abstract public function runComponentEffects():Void;

  public function shouldComponentRender():Bool {
    return true;
  }

  override function dispose() {
    __platform = null;
    super.dispose();
  }

  function getConcreteManager():ConcreteManager {
    return __manager;
  }

  override function __registerPlatform(platform:Platform) {
    __platform = platform;
    __manager = __platform.createManagerForComponent(this);
    addDisposable(__manager);
  }

  abstract function __beforeHooks():Void;

  public function __performUpdate(registerEffect:(task:()->Void)->Void) {
    try {
      Differ.diffChildren(this, __performRender(), __platform, registerEffect);
      registerEffect(runComponentEffects);
    } catch (e) switch __status {
      case WidgetRecovering(e):
        throw e;
      default:
        __status = WidgetRecovering(e);
        __performUpdate(registerEffect);
    }
  }
  
  function __performRender():VNodeResult {
    var exception:Null<Exception> = null;
    var vnr:VNodeResult = new VNodeResult(VNone);

    try {
      __beforeHooks();
      vnr = switch __status {
        case WidgetRecovering(error):
          componentDidCatch(error);
        default:
          render();
      }
    } catch (e:BlokException) {
      exception = e;
    } catch (e) {
      exception = new WrappedException(e, this);
    }

    if (exception != null) throw exception;

    if (vnr == null) {
      return new VNodeResult(VNone);
    }

    return vnr;
  }
}

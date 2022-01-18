package blok.ui;

@:autoBuild(blok.ui.ComponentBuilder.build())
abstract class Component extends Widget {
  var __currentRevision:Int = 0;
  var __lastRevision:Int = 0;
  var __manager:ConcreteManager = null;

  abstract public function updateComponentProperties(props:Dynamic):Void;
  
  abstract function render():VNodeResult;

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
    __manager = __createConcreteManager(platform);
    addDisposable(__manager);
  }

  function __createConcreteManager(platform:Platform):ConcreteManager {
    return __platform.createManagerForComponent(this);
  }

  abstract function __beforeHooks():Void;

  public function __performUpdate(registerEffect:(task:()->Void)->Void) {
    Differ.diffChildren(this, __performRender(), __platform, registerEffect);
    registerEffect(runComponentEffects);
  }
  
  function __performRender():VNodeResult {
    __beforeHooks();
    return switch render() {
      case null: new VNodeResult(VNone);
      case vnode: vnode; 
    }
  }
}

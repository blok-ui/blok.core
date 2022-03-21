package blok.ui;

@:autoBuild(blok.ui.ComponentBuilder.build())
abstract class Component extends Widget {
  var __currentRevision:Int = 0;
  var __lastRevision:Int = 0;
  var __applicator:Applicator = null;

  abstract public function updateComponentProperties(props:Dynamic):Void;
  
  abstract function render():VNodeResult;

  public function shouldComponentRender():Bool {
    return true;
  }

  override function dispose() {
    __platform = null;
    super.dispose();
  }

  function getApplicator():Applicator {
    return __applicator;
  }

  override function __registerPlatform(platform:Platform) {
    __platform = platform;
    __applicator = __createApplicator(platform);
    addDisposable(__applicator);
  }

  function __createApplicator(platform:Platform):Applicator {
    return __platform.createComponentApplicator(this);
  }

  abstract function __beforeHooks():Void;

  abstract function __registerEffects(effects:Effect):Void;

  public function __performUpdate(effects:Effect) {
    Differ.diffChildren(this, __performRender(), __platform, effects);
    __registerEffects(effects);
  }
  
  function __performRender():VNodeResult {
    __beforeHooks();
    return switch render() {
      case null: new VNodeResult(VNone);
      case vnode: vnode; 
    }
  }
}

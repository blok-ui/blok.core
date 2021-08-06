package blok;

import blok.WidgetType.getUniqueTypeId;

class PlatformWidget extends Widget {
  static final platformType = getUniqueTypeId();
  
  public final root:ConcreteWidget;
  final platform:Platform;

  public function new(root, platform) {
    this.root = root;
    this.platform = platform;
  }

  public function getPlatform() {
    return platform;
  }

  public function mount() {
    switch __status {
      case WidgetPending:
        var effects:Array<()->Void> = [];
        function registerEffect(effect:()->Void) effects.push(effect);

        initializeWidget(null, platform);
        __status = WidgetRendering;

        root.initializeWidget(this, platform);
        root.performUpdate(registerEffect);
        addChild(root);
        for (effect in effects) effect();
        
        __status = WidgetValid;
      default:
        throw 'Widget already mounted';
    }
  }

  public function getWidgetType():WidgetType {
    return platformType;
  }

  public function getConcreteManager():ConcreteManager {
    throw 'PlatformWidgets should never recieve this call -- make '
    + 'sure the PlatformWidget is implemented properly in your '
    + 'PlatformWidget implementation.';
  }

  public function __performUpdate(registerEffect:(task:()->Void)->Void) {
    throw 'PlatformWidgets should never recieve this call -- make '
      + 'sure the PlatformWidget is implemented properly in your '
      + 'PlatformWidget implementation.';
  }
}

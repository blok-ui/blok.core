package impl;

import blok.ui.*;
import blok.core.DefaultScheduler;

using impl.Tools;

class TestingPlatform extends Platform {
  public static function mount(?child:VNode, ?effect:(res:String)->Void) {
    var children = child == null ? [] : [ child ];
    var platform = new TestingPlatform(new DefaultScheduler());
    var root = new RootWidget(children);
    
    platform.mountRootWidget(root, () -> {
      if (effect != null) effect(root.stringifyWidget());
    });

    return root;
  }

  public function createManagerForComponent(component:Component):ConcreteManager {
    return new ComponentConcreteManager(component);
  }
}

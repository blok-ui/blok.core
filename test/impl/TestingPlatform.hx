package impl;

import blok.render.ObjectCursor;
import blok.core.DefaultScheduler;
import blok.ui.Widget;
import blok.render.Platform;
import impl.TestingRootWidget;

class TestingPlatform extends Platform {
  public static function mount(?child:Widget, ?handler:(result:TestingObject)->Void):TestingRootElement {
    var platform = new TestingPlatform(DefaultScheduler.getInstance());
    var object = new TestingObject('');
    return cast platform.mountRootWidget(new TestingRootWidget(object, platform, child), () -> {
      if (handler != null) handler(object);
    });
  }

  public static function hydrate(object:TestingObject, ?child:Widget, ?handler:(result:TestingObject)->Void):TestingRootElement {
    var platform = new TestingPlatform(DefaultScheduler.getInstance());
    var cursor = new ObjectCursor(object);
    return cast platform.hydrateRootWidget(cursor, new TestingRootWidget(cursor.current(), platform, child), () -> {
      if (handler != null) handler(object);
    });
  }

  public function createPlaceholderObject(widget:Widget):Dynamic {
    return new TestingObject('');
  }
}

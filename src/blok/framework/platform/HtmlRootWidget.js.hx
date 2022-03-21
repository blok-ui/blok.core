package blok.framework.platform;

import blok.core.UniqueId;

class HtmlRootWidget extends RootWidget {
  static final type = new UniqueId();
  
  public final el:js.html.Element;

  public function new(el, platform:HtmlPlatform, child) {
    super(platform, child);
    this.el = el;
  }

  public function getWidgetType():UniqueId {
    return type;
  }

  public function createElement():Element {
    return new HtmlRootElement(this);
  }
}

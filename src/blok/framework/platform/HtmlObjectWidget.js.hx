package blok.framework.platform;

import blok.core.UniqueId;

class HtmlObjectWidget extends ObjectWidget {
  private static final types:Map<String, UniqueId> = [];

  public final tag:String;
  public final attrs:Dynamic;
  public final children:Array<Widget>;

  public function new(tag, attrs, children, ?key) {
    this.tag = tag;
    this.attrs = attrs;
    this.children = children;
    super(key);
  }

  public function getChildren():Array<Widget> {
    return children;
  }

  public function getWidgetType():UniqueId {
    if (!types.exists(tag)) {
      types.set(tag, new UniqueId());
    }
    return types.get(tag);
  }

  public function createElement():Element {
    return new HtmlObjectElement(this);
  }
}
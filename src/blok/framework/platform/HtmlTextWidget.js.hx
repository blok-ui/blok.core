package blok.framework.platform;

import blok.core.UniqueId;

class HtmlTextWidget extends ObjectWidget {
  public static final type:UniqueId = new UniqueId();

  public final content:String;

  public function new(content, ?key) {
    super(key);
    this.content = content;
  }

	public function getChildren():Array<Widget> {
		return [];
	}

	public function getWidgetType():UniqueId {
    return type;
	}

	public function createElement():Element {
    return new HtmlTextElement(this);
	}
}

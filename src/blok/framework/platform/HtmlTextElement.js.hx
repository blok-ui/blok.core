package blok.framework.platform;

class HtmlTextElement extends ObjectElement {
  public function createObject():Dynamic {
    var concrete:HtmlTextWidget = cast widget;
    return new js.html.Text(concrete.content);
  }

  public function updateObject(?oldWidget:Widget) {
    var oldConcrete:HtmlTextWidget = cast oldWidget;
    var concrete:HtmlTextWidget = cast widget;
    var text:js.html.Text = object;

    if (oldConcrete.content != concrete.content) {
      text.textContent = concrete.content;
    }
  }

  override function visitChildren(visitor:ElementVisitor) {
    // noop
  }
}

package helpers;

import blok.Html;
import blok.Component;

class SimpleComponent extends Component {
  @prop public var className:String;
  @prop public var content:String;
  @prop var test:(comp:SimpleComponent)->Void = null;
  public var ref:js.html.Element = null;

  @effect
  public function maybeRunTest() {
    if (test != null) test(this);
  }

  @update
  public function setContent(content) {
    return UpdateState({ content: content });
  }
  
  override function render(context) {
    return Html.h('p', { className: className }, [ Html.text(content) ], node -> ref = cast node);
  }
}

package helpers;

import blok.VNode;
import blok.Html;
import blok.Component;
import blok.Context;

class Host extends Component {
  @prop var children:Array<VNode>;
  @prop var onComplete:(node:js.html.Node)->Void;
  var ref:js.html.Node;

  @effect
  function handleOnComplete() {
    onComplete(ref);
  }

  public function render() {
    return Html.h('div', {}, children, node -> ref = node);
  }
}

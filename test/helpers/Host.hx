package helpers;

import blok.VNode;
import blok.Html;
import blok.Component;
import blok.Context;

class Host extends Component {
  @prop var children:Array<VNode>;
  @prop var onComplete:()->Void;

  @effect
  function handleOnComplete() {
    onComplete();
  }

  override function render(context:Context) {
    return Html.fragment(children);
  }
}

package helpers;

import blok.Html;
import blok.Context;
import blok.Component;

@lazy
class LazyComponent extends Component {
  @prop var foo:String;
  @prop var bar:String;
  @prop var test:(comp:LazyComponent)->Void;

  @effect
  public function runTest() {
    test(this);
  }

  override function render(context:Context) {
    return Html.text(foo + ' | ' + bar);
  }
}

package medic;

import blok.ui.Component;
import blok.ui.VNode;

class TestableComponent extends Component {
  @prop var children:Array<VNode>;
  @prop var test:(comp:TestableComponent)->Void = null;

  @effect
  public function maybeRunTest() {
    if (test != null) test(this);
  }
  
  public function render() {
    return children;
  }
}

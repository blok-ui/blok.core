package medic;

import blok.ui.Component;
import blok.ui.Widget;
import impl.Node;

class TestableComponent extends Component {
  @prop var children:Array<Widget>;
  @prop var test:(comp:TestableComponent)->Void = null;

  @effect
  public function maybeRunTest() {
    if (test != null) test(this);
  }
  
  public function render() {
    return Node.fragment(...children);
  }
}

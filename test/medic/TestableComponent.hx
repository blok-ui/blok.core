package medic;

import blok.ui.Component;
import blok.ui.Widget;
import impl.Node;

class TestableComponent extends Component {
  @prop var children:Array<Widget>;
  @prop var test:(comp:TestableComponent)->Void = null;

  @after
  public function maybeRunTest() {
    if (test != null) {
      platform
        .getRootElement()
        .getObservable()
        .next(_ -> test(this));
    }
  }
  
  public function render() {
    return Node.fragment(...children);
  }
}

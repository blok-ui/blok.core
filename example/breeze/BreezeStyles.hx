package breeze;

import blok.signal.*;
import blok.ui.*;

class BreezeStyles extends Component {
  @:observable final styles:ClassName;
  @:constant final child:Child;

  var previousClassList:Array<String> = [];

  function setup() {
    Observer.track(() -> {
      #if (js && !nodejs)
      var el:js.html.Element = getRealNode();
      var cls = styles().toArray();
      for (name in previousClassList) {
        if (!cls.contains(name)) el.classList.remove(name);
        cls.remove(name);
      }
      previousClassList = cls;
      if (cls.length > 0) {
        el.classList.add(...cls);
      }
      #else
      getAdaptor().updateNodeAttribute(getRealNode(), 'class', styles());
      #end
    });
  }

  function render() {
    return child;
  }
}

package html;

import blok.*;

class Fragment extends Component {
  @prop var children:Array<VNode>;

  function render() {
    return children;
  }
}

// class Fragment implements VNode {
//   public final type:WidgetType = FragmentWidget.type;
//   public final key:Null<Key>;
//   public final props:Dynamic;
//   public final children:Null<Array<VNode>>;

//   public function new(children, ?key) {
//     this.props = {};
//     this.key = key;
//     this.children = children;
//   }

//   public function createWidget(?parent:Widget, platform:Platform, registerEffect:(effect:()->Void)->Void):Widget {
//     var widget = new FragmentWidget(children);
//     widget.initializeWidget(parent, platform, key);
//     widget.performUpdate(registerEffect);
//     return widget;
//   }

//   public function updateWidget(widget:Widget, registerEffect:(effect:()->Void)->Void):Widget {
//     var fragment:FragmentWidget = cast widget;
//     fragment.setChildren(children);
//     fragment.performUpdate(registerEffect);
//     return widget;
//   }
// }

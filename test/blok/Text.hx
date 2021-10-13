package blok;

import blok.VNode;

class Text {
  public static function stringifyWidget(comp:Widget) {
    var text:Array<String> = [];
    for (child in comp.getChildConcreteManagers()) text = text.concat(cast child.toConcrete());
    return text.filter(t -> t.length > 0).join(' ');
  }

  public static function text(text:String, ?key, ?ref):VNode {
    return TextWidget.node(text, key, ref);
  }

  public static function children(children:Array<VNode>, ?ref) {
    return ChildrenComponent.node({ children: children, ref: ref });
  }
}

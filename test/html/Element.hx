package html;

import js.Browser;
import blok.*;
import blok.WidgetType.getUniqueTypeId;

class Element implements VNode {
  static final elementTypes:Map<String, WidgetType> = [];

  public static function getElementType(tag:String) {
    return elementTypes.exists(tag)
    ? elementTypes.get(tag)
    : {
      elementTypes.set(tag, getUniqueTypeId());
      elementTypes.get(tag);
    };
  }

  public final tag:String;
  public final type:WidgetType;
  public final key:Null<Key>;
  public final props:Dynamic;
  public final children:Null<Array<VNode>>;

  public function new(tag, props, ?key, ?children) {
    this.tag = tag;
    this.type = getElementType(tag);
    this.props = props;
    this.key = key;
    this.children = children;
  }

  public function createWidget(?parent:Widget, platform:Platform, registerEffect:(effect:()->Void)->Void):Widget {
    var widget = new ElementWidget(
      Browser.document.createElement(tag),
      type,
      props,
      children
    );
    widget.initializeWidget(parent, platform, key);
    widget.performUpdate(registerEffect);
    return widget;
  }

  public function updateWidget(widget:Widget, registerEffect:(effect:()->Void)->Void):Widget {
    var elWid:ElementWidget<Dynamic> = cast widget;
    elWid.updateAttrs(props);
    elWid.setChildren(children);
    elWid.performUpdate(registerEffect);
    return widget;
  }
}

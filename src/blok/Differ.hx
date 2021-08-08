package blok;

// Adapted from superfine: https://github.com/jorgebucaran/superfine
@:nullSafety
final class Differ {
  public static function diffWidget(
    parent:Widget,
    widget:Null<Widget>,
    vNode:VNode,
    platform:Platform,
    registerEffect:(effect:()->Void)->Void
  ) {
    if (widget == null || vNode.type != widget.getWidgetType()) {
      parent.replaceChild(widget, vNode.createWidget(parent, platform, registerEffect));
    } else {
      vNode.updateWidget(widget, registerEffect);
    }
  }

  public static function diffChildren(
    parent:Widget,
    vnodes:Array<VNode>,
    platform:Platform,
    registerEffect:(effect:()->Void)->Void
  ) {
    vnodes = flatten(vnodes, parent);

    var children = parent.getChildren().copy();
    var oldKey:Null<Key> = null;
    var newKey:Null<Key> = null;
    var oldHead = 0;
    var newHead = 0;
    var oldTail = children.length - 1;
    var newTail = vnodes.length - 1;

    while (newHead < newTail && oldHead < oldTail) {
      if (
        (oldKey = getKey(children[oldHead])) == null 
        || oldKey != vnodes[newHead].key
      ) break;

      diffWidget(
        parent,
        children[oldHead++],
        vnodes[newHead++],
        platform,
        registerEffect
      );
    }

    while (newHead < newTail && oldHead < oldTail) {
      if (
        (oldKey = getKey(children[oldTail])) == null 
        || oldKey != vnodes[newTail].key
      ) break;

      diffWidget(
        parent,
        children[oldTail--],
        vnodes[newTail--],
        platform,
        registerEffect
      );
    }

    if (oldHead > oldTail) {
      while (newHead <= newTail) {
        parent.insertChildBefore(
          children[oldHead],
          vnodes[newHead++].createWidget(parent, platform, registerEffect)
        );
      }
    } else if (newHead > newTail) {
      while (oldHead <= oldTail) {
        parent.removeChild(children[oldHead++]);
      }
    } else {
      var keyed:KeyMap<Widget> = new KeyMap();
      var newKeyed:KeyMap<Bool> = new KeyMap();
      var existingWidget:Null<Widget> = null;

      for (i in oldHead...(oldTail+1)) {
        oldKey = getKey(children[i]);
        if (oldKey != null) keyed.set(oldKey, children[i]);
      }

      while (newHead <= newTail) {
        oldKey = getKey((existingWidget = children[oldHead]));
        newKey = getVNodeKey(vnodes[newHead]);

        var hasKey = oldKey != null && newKeyed.get(oldKey);

        if (hasKey || (newKey != null && newKey == getKey(children[oldHead + 1]))) {
          if (oldKey == null) {
            parent.removeChild(existingWidget);
          }
          oldHead++;
          continue;
        }

        if (newKey == null) {
          if (oldKey == null) {
            diffWidget(
              parent,
              existingWidget,
              vnodes[newHead],
              platform,
              registerEffect
            );
            newHead++;
          }
          oldHead++;
        } else {
          if (oldKey == newKey) {
            diffWidget(
              parent,
              existingWidget,
              vnodes[newHead],
              platform,
              registerEffect
            );
            newKeyed.set(newKey, true);
            oldHead++;
          } else {
            var keyedWidget = keyed.get(newKey);
            if (keyedWidget != null) {
              var vn = vnodes[newHead];
              parent.moveChildTo(
                newHead,
                vn.updateWidget(keyedWidget, registerEffect)
              );
              newKeyed.set(newKey, true);
            } else {
              parent.insertChildAt(
                newHead,
                vnodes[newHead].createWidget(parent, platform, registerEffect)
              );
            }
          }

          newHead++;
        }
      }

      while (oldHead <= oldTail) {
        if (getKey((existingWidget = children[oldHead++])) == null) {
          parent.removeChild(existingWidget);
        }
      }

      keyed.each((key, comp) -> {
        if (newKeyed.get(key) == null) {
          parent.removeChild(comp);
        }
      });
    }
  }

  static function getVNodeKey(vNode:VNode) {
    return if (vNode == null) null else vNode.key;
  }

  static function getKey(widget:Null<Widget>) {
    return if (widget == null) null else widget.getWidgetKey();
  }

  static function flatten(vnodes:Array<VNode>, parent:Widget) {
    if (vnodes == null) return [];
    return vnodes.filter(vn -> vn != null);
  }
}

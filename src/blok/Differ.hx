package blok;

// Adapted from superfine: https://github.com/jorgebucaran/superfine
@:nullSafety
final class Differ {
  final engine:Engine;

  public function new(engine) {
    this.engine = engine;
  }

  public function patchComponent(component:Component, vnodes:Array<VNode>) {
    diffChildren(component, vnodes);
  }

  public function diffComponent(
    parent:Component,
    component:Null<Component>,
    vNode:VNode
  ) {
    if (component == null || vNode.type != component.getComponentType()) {
      parent.replaceChild(component, vNode.createComponent(engine, parent));
    } else {
      vNode.updateComponent(engine, component);
    }
  }

  public function diffChildren(
    parent:Component,
    vnodes:Array<VNode>
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

      diffComponent(
        parent,
        children[oldHead++],
        vnodes[newHead++]
      );
    }

    while (newHead < newTail && oldHead < oldTail) {
      if (
        (oldKey = getKey(children[oldTail])) == null 
        || oldKey != vnodes[newTail].key
      ) break;

      diffComponent(
        parent,
        children[oldTail--],
        vnodes[newTail--]
      );
    }

    if (oldHead > oldTail) {
      while (newHead <= newTail) {
        parent.insertChildBefore(
          children[oldHead],
          vnodes[newHead++].createComponent(engine, parent)
        );
      }
    } else if (newHead > newTail) {
      while (oldHead <= oldTail) {
        parent.removeChild(children[oldHead++]);
      }
    } else {
      var keyed:KeyMap<Component> = new KeyMap();
      var newKeyed:KeyMap<Bool> = new KeyMap();
      var existingComponent:Null<Component> = null;

      for (i in oldHead...(oldTail+1)) {
        oldKey = getKey(children[i]);
        if (oldKey != null) keyed.set(oldKey, children[i]);
      }

      while (newHead <= newTail) {
        oldKey = getKey((existingComponent = children[oldHead]));
        newKey = getVNodeKey(vnodes[newHead]);

        var hasKey = oldKey != null && newKeyed.get(oldKey);

        if (hasKey || (newKey != null && newKey == getKey(children[oldHead + 1]))) {
          if (oldKey == null) {
            parent.removeChild(existingComponent);
          }
          oldHead++;
          continue;
        }

        if (newKey == null) {
          if (oldKey == null) {
            diffComponent(
              parent,
              existingComponent,
              vnodes[newHead]
            );
            newHead++;
          }
          oldHead++;
        } else {
          if (oldKey == newKey) {
            diffComponent(
              parent,
              existingComponent,
              vnodes[newHead]
            );
            newKeyed.set(newKey, true);
            oldHead++;
          } else {
            var keyedComponent = keyed.get(newKey);
            if (keyedComponent != null) {
              var vn = vnodes[newHead];
              parent.moveChildTo(
                newHead,
                vn.updateComponent(engine, keyedComponent)
              );
              newKeyed.set(newKey, true);
            } else {
              parent.insertChildAt(
                newHead,
                vnodes[newHead].createComponent(engine, parent)
              );
            }
          }

          newHead++;
        }
      }

      while (oldHead <= oldTail) {
        if (getKey((existingComponent = children[oldHead++])) == null) {
          parent.removeChild(existingComponent);
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

  static function getKey(component:Null<Component>) {
    return if (component == null) null else component.getComponentKey();
  }

  static function flatten(vnodes:Array<VNode>, parent:Component) {
    return vnodes.filter(vn -> vn != null);
  }
}

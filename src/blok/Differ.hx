package blok;

import blok.VNodeType.fragmentType;

// Adapted from superfine: https://github.com/jorgebucaran/superfine
@:nullSafety
class Differ {
  static var instance:Null<Differ> = null;

  public static function getInstance():Differ {
    if (instance == null) {
      instance = new Differ();
    }
    return instance;
  }

  public function new() {}

  public function getPlaceholder():VNode {
    return VFragment.empty();
  }

  public function patchComponent(component:Component, vnodes:Array<VNode>, isInit:Bool) {
    diffChildren(component, vnodes);
  }

  public function diffComponent(
    parent:Component,
    component:Null<Component>,
    vNode:VNode
  ) {
    if (component == null || vNode.type != component.getComponentType()) {
      parent.replaceComponent(component, vNode.createComponent(parent));
    } else {
      vNode.updateComponent(component);
    }
  }

  public function diffChildren(
    parent:Component,
    vnodes:Array<VNode>
  ) {
    vnodes = flatten(vnodes);

    var children = parent.getChildComponents().copy();
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
        parent.insertComponentBefore(
          children[oldHead],
          vnodes[newHead++].createComponent(parent)
        );
      }
    } else if (newHead > newTail) {
      while (oldHead <= oldTail) {
        parent.removeComponent(children[oldHead++]);
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
            parent.removeComponent(existingComponent);
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
              parent.moveComponentTo(
                newHead,
                vn.updateComponent(keyedComponent)
              );
              newKeyed.set(newKey, true);
            } else {
              parent.insertComponentAt(
                newHead,
                vnodes[newHead].createComponent(parent)
              );
            }
          }

          newHead++;
        }
      }

      while (oldHead <= oldTail) {
        if (getKey((existingComponent = children[oldHead++])) == null) {
          parent.removeComponent(existingComponent);
        }
      }

      keyed.each((key, comp) -> {
        if (newKeyed.get(key) == null) {
          parent.removeComponent(comp);
        }
      });
    }
  }

  function getVNodeKey(vNode:VNode) {
    return if (vNode == null) null else vNode.key;
  }

  function getKey(component:Null<Component>) {
    return if (component == null) null else component.getComponentKey();
  }

  function flatten(vnodes:Array<VNode>) {
    return vnodes.filter(vn -> vn != null);
  }
}

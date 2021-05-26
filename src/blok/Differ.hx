package blok;

import blok.VNodeType.noneType;
import blok.VNodeType.fragmentType;

@:nullSafety
class Differ {
  public static function diffComponent(
    parent:Component,
    component:Null<Component>,
    vNode:VNode
  ) {
    if (component == null || vNode.type != component.getComponentType()) {
      parent.replaceComponent(component, createComponent(parent, vNode));
    } else {
      updateComponent(component, vNode);
    }
  }

  public static function diffChildren(
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

    if (oldHead > newTail) {
      while (newHead <= newTail) {
        parent.insertComponentBefore(
          children[oldHead],
          createComponent(parent, vnodes[newHead++])
        );
      }
    } else if (newHead > newTail) {
      while (oldHead <= oldTail) {
        parent.removeComponent(children[oldHead++]);
      }
    } else {
      var keyed:Map<Key, Component> = new Map();
      var newKeyed:Map<Key, Bool> = new Map();
      var existingComponent:Null<Component> = null;

      for (i in oldHead...oldTail) {
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
              updateComponent(keyedComponent, vnodes[newHead]);
              parent.moveComponentTo(
                oldHead,
                keyedComponent
              );
            } else {
              diffComponent(
                parent,
                null,
                vnodes[newHead]
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

      for (key => comp in keyed) {
        if (newKeyed[key] == null) {
          parent.removeComponent(comp);
        }
      }
    }
  }

  static function getVNodeKey(vNode:VNode) {
    return if (vNode == null) null else vNode.key;
  }

  static function getKey(component:Null<Component>) {
    return if (component == null) null else component.getComponentKey();
  }

  static function createComponent(parent:Component, vNode:VNode) {
    var component = vNode.createComponent();
    component.initializeComponent(parent, vNode.key);
    component.renderComponent();
    return component;
  }
  
  static function updateComponent(component:Component, vNode:VNode) {
    component.updateComponentProperties(vNode.props);
    if (component.shouldComponentUpdate()) {
      component.renderComponent();
    }
    return component;
  }

  static function flatten(vnodes:Array<VNode>) {
    var flattened:Array<VNode> = [];
    for (vn in vnodes) if (vn != null && vn.type != noneType) { 
      if (vn.type == fragmentType) {
        if (vn.children != null) {
          flattened = flattened.concat(flatten(vn.children));
        }
      } else {
        flattened.push(vn);
      }
    }
    return flattened;
  }
}

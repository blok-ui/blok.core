package blok;

import blok.VNodeType.noneType;
import blok.VNodeType.fragmentType;

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

  public function patchComponent(component:Component, vnodes:Array<VNode>, isInit:Bool) {
    diffChildren(component, vnodes);
  }

  public function diffComponent(
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
                updateComponent(keyedComponent, vn)
              );
              newKeyed.set(newKey, true);
            } else {
              parent.insertComponentAt(
                newHead,
                createComponent(parent, vnodes[newHead])
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

  function createComponent(parent:Component, vNode:VNode) {
    var component = vNode.createComponent();
    component.initializeComponent(parent, vNode.key);
    component.renderComponent();
    return component;
  }
  
  function updateComponent(component:Component, vNode:VNode) {
    vNode.updateComponent(component);
    if (component.shouldComponentUpdate()) {
      component.renderComponent();
    }
    return component;
  }

  function flatten(vnodes:Array<VNode>) {
    var flattened:Array<VNode> = [];
    // todo: not including nulls and noneTypes will probably 
    //       break things?
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

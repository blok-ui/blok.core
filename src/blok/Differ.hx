package blok;

import haxe.ds.Option;

class Differ {
  public static function initialize(
    node:VNode,
    parent:Null<Component>
  ) {
    function process(nodes:Array<VNode>) for (n in nodes) {
      switch n {
        case VNone | null:
          // noop
        case VComponent(type, properties, key):
          var comp = type.create(properties);
          if (parent != null) parent.addComponent(comp, key);
        case VFragment(nodes):
          process(nodes);
      }
    }

    process([ node ]);
  }
  
  public static function diff(
    node:VNode,
    parent:Component
  ) {
    var cursor = new ComponentCursor(parent);

    function previous(key:Null<Key>):Option<Component> {
      if (key != null) {
        var keyed = parent.findComponentByKey(key);
        return if (keyed != null) {
          cursor.move(keyed);
          Some(keyed); 
        } else None;
      }

      var current = cursor.current();
      return if (current == null) None else Some(current);
    }

    function process(nodes:Array<VNode>) for (n in nodes) {
      switch n {
        case VNone | null:
          // noop
        case VComponent(type, properties, key): switch previous(key) {
          case None:
            var comp = type.create(properties);
            cursor.insert(comp, key);
            cursor.step();
          case Some(comp) if (comp.isComponentType(type)):
            type.update(cast comp, properties);
            if (comp.shouldComponentUpdate() || comp.componentIsInvalid()) {
              comp.renderComponent();
            }
            cursor.step();
          case Some(_):
            var comp = type.create(properties);
            cursor.replace(comp);
            cursor.step();
        }
        case VFragment(nodes):
          process(nodes);
      }
    }

    process([ node ]);

    // Remove excess
    var toDispose = [];
    while (cursor.current() != null) {
      toDispose.push(cursor.current());
      cursor.step();
    }
    if (toDispose.length > 0) for (item in toDispose) item.dispose();
  }
}
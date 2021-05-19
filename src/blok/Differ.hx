package blok;

import haxe.ds.Option;

class Differ {
  static var instance:Null<Differ>;

  public static function getInstance():Differ {
    if (instance == null) {
      instance = new Differ();
    }
    return instance;
  }

  final options:DifferOptions;

  public function new(?options) {
    this.options = options != null
      ? options
      : {};
  }

  public function initialize(
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

    switch node {
      case VNone | VFragment([]) | null if (options.createPlaceholder != null):
        var child = options.createPlaceholder(parent);
        if (child != null) parent.addComponent(child);
      default:
        process([ node ]);
    }
    
    if (options.onInitialize != null) options.onInitialize(parent);
  }
  
  public function diff(
    node:VNode,
    parent:Component
  ) {
    var previousComponents = parent.getChildComponents().copy();
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

    switch node {
      case VNone | VFragment([]) | null if (options.createPlaceholder != null):
        var child = options.createPlaceholder(parent);
        if (child != null) {
          cursor.insert(child);
          cursor.step();
        }
      default:
        process([ node ]);
    }

    // Remove excess
    while (cursor.current() != null) if (!cursor.delete()) break;

    if (options.onUpdate != null) options.onUpdate(parent, previousComponents);
  }
}
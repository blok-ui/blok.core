package blok.core;

import haxe.ds.Option;

@:nullSafety
class Differ {
  public static function initialize(
    node:VNode, 
    engine:Engine, 
    parent:Null<Component>
  ) {
    var rendered = new Rendered();

    function process(nodes:Array<VNode>) for (n in nodes) {
      switch n {
        case None:
          // noop
        case VComponent(type, properties, key):
          var comp = type.create(properties);
          comp.initializeComponent(engine, parent);
          rendered.addChild(type, key, comp);
        case VFragment(nodes):
          process(nodes);
      }
    }

    process([ node ]);

    return rendered;
  }

  public static function diff(
    node:VNode,
    engine:Engine,
    parent:Component,
    before:Rendered
  ):Rendered {
    var newRendered = new Rendered();

    function previous(type:ComponentType<Dynamic, Dynamic>, key:Null<Key>):Option<Component> {
      if (!before.hasRegistry(type)) return None;
      return switch before.getRegistry(type).pull(key) {
        case null: None;
        case v: Some(v);
      }
    }

    function process(nodes:Array<VNode>) for (n in nodes) {
      switch n {
        case None:
          // noop
        case VComponent(type, properties, key): switch previous(type, key) {
          case None:
            var comp = type.create(properties);
            comp.initializeComponent(engine, parent);
            newRendered.addChild(type, key, comp);
          case Some(comp):
            type.update(cast comp, properties);
            if (comp.shouldComponentUpdate() || comp.componentIsInvalid()) {
              comp.renderComponent();
            }
            newRendered.addChild(type, key, comp);
        }
        case VFragment(nodes):
          process(nodes);
      }
    }

    process([ node ]);
    
    // Remove any excess components
    for (registry in before.types) {
      registry.each(comp -> comp.dispose());
    }

    return newRendered;
  }
}

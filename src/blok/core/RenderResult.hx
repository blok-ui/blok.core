package blok.core;

import haxe.ds.Map;

@:access(blok.core.Component)
class RenderResult<RealNode> implements Disposable {
  final effects:Array<()->Void> = [];
  final engine:Engine<RealNode>;
  public final types:Map<{}, TypeRegistry<RealNode>> = [];
  public final children:Array<RNode<RealNode>> = [];

  public function new(context:Context<RealNode>) {
    engine = context.engine;
  }

  public function getNodes():Array<RealNode> {
    var nodes:Array<RealNode> = [];
    for (r in children)
      switch r {
        case RNative(node, _):
          nodes.push(node);
        case RComponent(child):
          nodes = nodes.concat(child.getLastRenderResult().getNodes());
      }
    return nodes;
  }

  public function dispose() {
    for (r in types) r.each(item -> switch item {
      case RComponent(component):
        component.dispose();
      case RNative(node, _):
        var sub = engine.getRendered(node);
        if (sub != null) sub.dispose();
    });
  }

  public function add(?key:Key, type:{}, r:RNode<RealNode>) {
    if (!types.exists(type)) {
      types.set(type, new TypeRegistry());
    }
    
    types.get(type).put(key, r);
    children.push(r);
    switch r {
      case RComponent(component):
        for (e in component.getSideEffects()) addEffect(e);
      default:
    }
  }

  public function addEffect(effect:()->Void) {
    effects.push(effect);
  }

  public function dispatchEffects() {
    for (r in children) switch r {
      case RComponent(component):
        component.getLastRenderResult().dispatchEffects();
      default:
    }

    if (effects.length > 0) {
      var e = effects.pop();
      do e() while ((e = effects.pop()) != null);
    }
  }
}

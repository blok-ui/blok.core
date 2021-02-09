package blok.core;

import haxe.ds.Option;
import haxe.DynamicAccess;

typedef Diff<RealNode> = (
  nodes:Array<VNode<RealNode>>,
  parent:Null<Component<RealNode>>,
  context:Context<RealNode>
) -> RenderResult<RealNode>;

class Differ {
  static final EMPTY = {};
  
  public static function diffObject<RealNode>(
    oldProps:DynamicAccess<Dynamic>,
    newProps:DynamicAccess<Dynamic>,
    apply:(key:String, oldValue:Dynamic, newValue:Dynamic)->Void
  ) {
    if (oldProps == newProps) return;

    var keys = (if (newProps == null) {
      newProps = EMPTY;
      oldProps;
    } else if (oldProps == null) {
      oldProps = EMPTY;
      newProps;
    } else {
      var ret = newProps.copy();
      for (key in oldProps.keys()) ret[key] = true;
      ret;
    }).keys();

    for (key in keys) switch [ oldProps[key], newProps[key] ] {
      case [ a, b ] if (a == b):
      case [ a, b ]: apply(key, a, b);
    }
  }

  public inline static function renderWithSideEffects<RealNode>(
    node:RealNode, 
    nodes:Array<VNode<RealNode>>,
    parent:Null<Component<RealNode>>,
    context:Context<RealNode>
  ):RenderResult<RealNode> {
    return render(node, nodes, parent, context, true);
  }

  public static function render<RealNode>(
    node:RealNode, 
    nodes:Array<VNode<RealNode>>,
    parent:Null<Component<RealNode>>,
    context:Context<RealNode>,
    withSideEffects:Bool = false
  ) {
    var engine = context.engine;

    inline function handleRendered(previousCount, rendered) {
      engine.setRenderResult(node, rendered);
      setChildren(previousCount, engine.traverseChildren(node), rendered);
      if (withSideEffects) rendered.dispatchEffects();
    }

    return switch engine.getRenderResult(node) {
      case null: 
        renderAll(nodes, parent, context, rendered -> handleRendered(0, rendered));
      case before: 
        var previousCount = before.getNodes().length;
        updateAll(before, nodes, parent, context, rendered -> handleRendered(previousCount, rendered));
    }
  }

  public static function renderAll<RealNode>(
    nodes:Array<VNode<RealNode>>,
    parent:Null<Component<RealNode>>,
    context:Context<RealNode>,
    ?handle:(rendered:RenderResult<RealNode>)->Void
  ):RenderResult<RealNode> {
    var differ = createDiff((_, _) -> None);
    var result = differ(nodes, parent, context);
    if (handle != null) handle(result);
    return result;
  }

  public static function updateAll<RealNode>(
    before:RenderResult<RealNode>,
    nodes:Array<VNode<RealNode>>,
    parent:Null<Component<RealNode>>,
    context:Context<RealNode>,
    ?handle:(rendered:RenderResult<RealNode>)->Void
  ):RenderResult<RealNode> {
    var differ = createDiff((type, key) -> {
      var registry = before.types.get(type);
      if (registry == null) return None;
      return switch registry.pull(key) {
        case null: None;
        case v: Some(v);
      }
    });
    var result = differ(nodes, parent, context);

    if (handle != null) handle(result);
    before.dispose();

    return result;
  }

  public static function setChildren<Node>(
    previousCount:Int,
    cursor:Cursor<Node>,
    next:RenderResult<Node>
  ) {
    var insertedCount = 0;
    var currentCount = 0;

    for (node in next.getNodes()) {
      currentCount++;
      if (node == cursor.current()) cursor.step();
      else if (cursor.insert(node)) insertedCount++;
    }

    var deleteCount = previousCount + insertedCount - currentCount;
    
    for (i in 0...deleteCount) {
      if (!cursor.delete()) break;
    }
  }

  static function createDiff<RealNode>(previous:(type:Dynamic, key:Key)->Option<RNode<RealNode>>):Diff<RealNode> {
    return function differ(
      nodes:Array<VNode<RealNode>>,
      parent:Null<Component<RealNode>>,
      context:Context<RealNode>
    ) {
      var result = new RenderResult(context);

      function process(nodes:Array<VNode<RealNode>>) {
        if (nodes != null) for (n in nodes) if (n != null) {
          switch n {
            case VNative(type, props, ref, key, children): switch previous(type, key) {
              case None:
                var node = type.create(props, context);
                render(node, children, parent, context);
                if (ref != null) result.addEffect(() -> ref(node));
                result.add(key, type, RNative(node, props));
              case Some(r): switch r {
                case RNative(node, lastProps):
                  type.update(node, lastProps, props, context);
                  render(node, children, parent, context);
                  result.add(key, type, RNative(node, props));
                default: throw 'assert';
              }
              default: throw 'assert';
            }
            
            case VComponent(type, props, key): switch previous(type, key) {
              case None:
                var component = type.create(props, parent, context);
                result.add(key, type, RComponent(component));
              case Some(r): switch r {
                case RComponent(component):
                  type.update(component, props, parent, context);
                  result.add(key, type, RComponent(component));
                default:
                  throw 'assert';
              }
              default:
                throw 'assert';
            }

            case VFragment(children, key):
              // todo: handle key?
              process(children);
          }
        }
      }

      process(nodes);
      return result;
    }
  }
}
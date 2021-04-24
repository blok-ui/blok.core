package blok.dom;

import js.html.Node;
import js.html.Text;
import blok.core.Differ;
import blok.core.DefaultScheduler;
import blok.core.Scheduler;
import blok.core.Rendered;

class DomEngine implements Engine {
  final scheduler:Scheduler;
  final context:Context;

  public function new(?context, ?scheduler) {
    this.context = context == null ? new Context() : context;
    this.scheduler = scheduler == null ? new DefaultScheduler() : scheduler;
  }

  public function initialize(component:Component) {
    return switch Std.downcast(component, NativeComponent) {
      case null:
        var result = Differ.initialize(component.render(context), this, component);
        if (result.children.length == 0) {
          var placeholder = TextType.create({ content: '' });
          placeholder.initializeComponent(this, component);
          result.addChild(TextType, null, placeholder);
        }
        var nodes = getNodesFromRendered(result);
        setChildren(0, new Cursor(nodes[0].parentNode, nodes[0]), result);
        result;
      case native if (!(native.node is Text)):
        var result = Differ.initialize(component.render(context), this, component);
        setChildren(0, new Cursor(native.node, native.node.firstChild), result);
        result;
      case _:
        new Rendered();
    }
  }

  public function update(component:Component) {
    return switch Std.downcast(component, NativeComponent) {
      case null:
        var previousCount = 0;
        var first:Node = null;
        var nodes = getNodesFromRendered(component.__renderedChildren);
        for (node in nodes) {
          if (first == null) first = node;
          previousCount++;
        }
        var result = Differ.diff(component.render(context), this, component, component.__renderedChildren);
        setChildren(previousCount, new Cursor(first.parentNode, first), result);
        result;
      case native:
        var previousCount = native.node.childNodes.length;
        var result = Differ.diff(component.render(context), this, component, component.__renderedChildren);
        setChildren(previousCount, new Cursor(native.node, native.node.firstChild), result);
        result;
    }
  }

  public function remove(component:Component) {
    switch Std.downcast(component, NativeComponent) {
      case null:
      case native:
        native.node.parentNode.removeChild(native.node);
    }
  }

  public function getContext():Context {
    return context;
  }

  public function withNewContext():Engine {
    return new DomEngine(context.getChild(), scheduler);
  }

  public function schedule(cb:()->Void):Void {
    scheduler.schedule(cb);
  }

  function getNodesFromRendered(rendered:Rendered) {
    var nodes:Array<Node> = [];
    for (child in rendered.children) switch Std.downcast(child, NativeComponent) {
      case null: 
        nodes = nodes.concat(getNodesFromRendered(child.__renderedChildren));
      case native:
        nodes.push(native.node);
    }
    return nodes;
  }

  function setChildren(
    previousCount:Int,
    cursor:Cursor,
    rendered:Rendered
  ) {
    var insertedCount = 0;
    var currentCount = 0;
    var nodes = getNodesFromRendered(rendered);

    for (node in nodes) {
      currentCount++;
      if (node == cursor.current()) cursor.step();
      else if (cursor.insert(node)) insertedCount++;
    }

    var deleteCount = previousCount + insertedCount - currentCount;
    
    for (i in 0...deleteCount) {
      if (!cursor.delete()) break;
    }
  }
}

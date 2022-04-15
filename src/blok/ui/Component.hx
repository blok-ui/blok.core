package blok.ui;

import blok.core.Debug;

@:autoBuild(blok.ui.ComponentBuilder.build())
abstract class Component extends Element {
  var childElement:Null<Element> = null;
  @:noCompletion var __isHydrating:Bool = false;

  abstract function render():Widget;
  
  function widgetHasChanged(current:Widget, previous:Widget) {
    return true;
  }

  function performBuild(previousWidget:Null<Widget>) {
    if (previousWidget == null) {
      performFirstBuild();
    } else if (previousWidget != widget) {
      if (widgetHasChanged(widget, previousWidget)) performBuildChild();
    } else {
      performBuildChild();
    }
  }

  function updateWidgetAndInvalidateElement(props:Dynamic) {
    Debug.assert(status == Active);
    Debug.assert(lifecycle != Building);

    var comp:ComponentWidget<Dynamic> = cast widget;
    var newWidget = comp.withProperties(props);

    if (widgetHasChanged(newWidget, comp)) {
      widget = newWidget;
      invalidate();
    } 
  }

  function visitChildren(visitor:ElementVisitor) {
    if (childElement != null) visitor.visit(childElement);
  }

  function performFirstBuild() {
    performInit();
    performBuildChild();
  }

  function performBuildChild() {
    performBefore();
    childElement = updateChild(childElement, render(), slot);
    performAfter();
  }

  function performHydrate(cursor:HydrationCursor):Void {
    __isHydrating = true;
    performInit();
    performBefore();
    childElement = hydrateElementForWidget(cursor, render(), slot);
    performAfter();
    __isHydrating = false;
  }

  inline function isHydrating() {
    return __isHydrating;
  }

  @:noCompletion function performInit() {}

  @:noCompletion function performBefore() {}

  @:noCompletion function performAfter() {}
}

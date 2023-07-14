package blok.boundary;

import blok.ui.ComponentBase;

function findBoundary(component:ComponentBase):Maybe<Boundary> {
  return switch component.findAncestor(component -> component is Boundary) {
    case Some(component): Some(cast component);
    case None: None;
  }
}

function tryToHandleWithBoundary(component:ComponentBase, object:Any) {
  switch findBoundary(component) {
    case Some(boundary): boundary.handle(component, object);
    case None: throw object;
  }
}

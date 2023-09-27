package blok.boundary;

import blok.ui.ComponentBase;

/**
  Find the nearest ancestor Component that implements Boundary.
**/
function findBoundary(component:ComponentBase):Maybe<Boundary> {
  return switch component.findAncestor(component -> component is Boundary) {
    case Some(component): Some(cast component);
    case None: None;
  }
}

/**
  Attempt to handle the given `object` with the nearest Boundary
  ancestor. If none is found, the `object` will be re-thrown.
**/
function tryToHandleWithBoundary(component:ComponentBase, object:Any) {
  switch findBoundary(component) {
    case Some(boundary): boundary.handle(component, object);
    case None: throw object;
  }
}

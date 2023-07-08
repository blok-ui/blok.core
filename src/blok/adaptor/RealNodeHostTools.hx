package blok.adaptor;

import blok.ui.*;

function findNearestRealNode(component:Component) {
  return component.findAncestor(component -> component is RealNodeHost)
    .map(component -> component.getRealNode())
    .orThrow('No real node found');
}

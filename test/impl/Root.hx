package impl;

import blok.ui.Child;
import blok.ui.RootComponent;
import blok.node.Node;

function mount(node:Node, child:Child) {
  var root = RootComponent.node({
    target: node,
    child: child,
    adaptor: new StaticAdaptor()
  });
  var component = root.createComponent();
  
  component.mount(null, null);
  return component;
}

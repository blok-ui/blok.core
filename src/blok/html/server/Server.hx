package blok.html.server;

import blok.node.*;
import blok.ui.*;

function mount(node:Node, child:()->Child) {
  var root = RootComponent.node({
    target: node,
    child: child,
    adaptor: new ServerAdaptor()
  });
  var component = root.createComponent();
  component.mount(null, null);
  return component;
}

function hydrate(node:Node, child:()->Child) {
  var adaptor = new ServerAdaptor();
  var root = RootComponent.node({
    target: node,
    child: child,
    adaptor: adaptor
  });
  var component = root.createComponent();
  component.hydrate(adaptor.createCursor(node), null, null);
  return component;
}

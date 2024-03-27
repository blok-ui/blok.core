package blok.html;

import blok.ui.*;
import blok.html.server.*;

function mount(node:Node, child:()->Child) {
  var root = Root.node({
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
  var root = Root.node({
    target: node,
    child: child,
    adaptor: adaptor
  });
  var component = root.createComponent();
  component.hydrate(adaptor.createCursor(node), null, null);
  return component;
}

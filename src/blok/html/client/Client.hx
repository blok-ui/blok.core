package blok.html.client;

import blok.ui.Child;
import js.html.Element;
import blok.ui.RootComponent;

function mount(el:Element, child:Child) {
  var root = RootComponent.node({
    target: el,
    child: child,
    adaptor: new ClientAdaptor()
  });
  var component = root.createComponent();
  component.mount(null, null);
  return component;
}

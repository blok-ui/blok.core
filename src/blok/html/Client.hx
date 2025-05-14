package blok.html;

import js.html.Node;
import blok.html.client.*;

function mount(primitive:ClientRootPrimitive, child:Child) {
	var root = new Root<Node>(primitive, new ClientAdaptor(), child);
	return root.mount();
}

function hydrate(primitive:ClientRootPrimitive, child:Child) {
	var root = new Root<Node>(primitive, new ClientAdaptor(), child);
	return root.hydrate();
}

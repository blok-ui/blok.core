package blok.html;

import blok.html.server.*;

function mount(primitive:ServerRootPrimitive, child:Child) {
	var root = new Root<NodePrimitive>(primitive, new ServerAdaptor(), child);
	return root.mount();
}

function hydrate(primitive:ServerRootPrimitive, child:Child) {
	var root = new Root<NodePrimitive>(primitive, new ServerAdaptor(), child);
	return root.hydrate();
}

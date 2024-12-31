package blok.html;

import blok.html.server.*;

function mount(primitive:ServerRootPrimitive, child:Child) {
	var root = Root.node({
		target: primitive,
		child: child
	});
	var component = root.createView();
	component.mount(new ServerAdaptor(), null, null);
	return component;
}

function hydrate(primitive:ServerRootPrimitive, child:Child) {
	var adaptor = new ServerAdaptor();
	var root = Root.node({
		target: primitive,
		child: child
	});
	var component = root.createView();
	component.hydrate(adaptor.createCursor(primitive), adaptor, null, null);
	return component;
}

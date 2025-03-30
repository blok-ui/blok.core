package blok.html;

import blok.html.server.*;

function mount(primitive:ServerRootPrimitive, child:Child):Root {
	var root = Root.node({target: primitive, child: child}).createView();
	root.mount(new ServerAdaptor(), null, null);
	return cast root;
}

function hydrate(primitive:ServerRootPrimitive, child:Child):Root {
	var adaptor = new ServerAdaptor();
	var root = Root.node({target: primitive, child: child}).createView();
	root.hydrate(adaptor.createCursor(primitive), adaptor, null, null);
	return cast root;
}

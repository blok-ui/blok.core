package blok.html;

import blok.html.client.*;

function mount(el:ClientRootNode, child:Child):Root {
	var root = Root.node({target: el, child: child}).createView();
	root.mount(new ClientAdaptor(), null, null);
	return cast root;
}

function hydrate(el:ClientRootNode, child:Child):Root {
	var adaptor = new ClientAdaptor();
	var root = Root.node({target: el, child: child}).createView();
	root.hydrate(adaptor.createCursor(el), adaptor, null, null);
	return cast root;
}

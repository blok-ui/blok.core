package blok.html;

import blok.html.client.*;
import blok.ui.*;

function mount(el:ClientRootNode, child:Child) {
	var root = Root.node({
		target: el,
		child: child
	});
	var component = root.createView();
	component.mount(new ClientAdaptor(), null, null);
	return component;
}

function hydrate(el:ClientRootNode, child:Child) {
	var adaptor = new ClientAdaptor();
	var root = Root.node({
		target: el,
		child: child
	});
	var component = root.createView();
	component.hydrate(adaptor.createCursor(el), adaptor, null, null);
	return component;
}

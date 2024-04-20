package blok.html;

import blok.ui.*;
import blok.html.server.*;

function mount(node:NodePrimitive, child:() -> Child) {
	var root = Root.node({
		target: node,
		child: child
	});
	var component = root.createComponent();
	component.mount(new ServerAdaptor(), null, null);
	return component;
}

function hydrate(node:NodePrimitive, child:() -> Child) {
	var adaptor = new ServerAdaptor();
	var root = Root.node({
		target: node,
		child: child
	});
	var component = root.createComponent();
	component.hydrate(adaptor.createCursor(node), adaptor, null, null);
	return component;
}

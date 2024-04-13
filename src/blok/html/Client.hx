package blok.html;

import blok.ui.*;
import blok.html.client.ClientAdaptor;
import js.html.Element;

function mount(el:Element, child:() -> Child) {
	var root = Root.node({
		target: el,
		child: child
	});
	var component = root.createComponent();
	component.mount(new ClientAdaptor(), null, null);
	return component;
}

function hydrate(el:Element, child:() -> Child) {
	var adaptor = new ClientAdaptor();
	var root = Root.node({
		target: el,
		child: child
	});
	var component = root.createComponent();
	component.hydrate(adaptor.createCursor(el), adaptor, null, null);
	return component;
}

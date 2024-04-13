package blok.adaptor;

import blok.ui.*;

function findNearestPrimitive(component:View) {
	return component.findAncestor(component -> component is PrimitiveHost)
		.map(component -> component.getPrimitive())
		.orThrow('No real node found');
}

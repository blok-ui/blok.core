package blok;

function findNearestPrimitive(component:View) {
	return component.findAncestor(component -> component is PrimitiveHost)
		.map(component -> component.getPrimitive())
		.orThrow('No primitive host found');
}

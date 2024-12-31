package blok;

/**
	Wraps a component in an ErrorBoundary, which will catch all errors
	and pass them to `fallback`.

	```haxe
	blok.Scope.wrap(_ -> {
	  throw 'Some error';
	}).inErrorBoundary(e -> {
	  return blok.Text.node(e.message);
	});
	```
**/
function inErrorBoundary(child:Child, fallback) {
	return ErrorBoundary.node({
		child: child,
		fallback: fallback
	});
}

package blok.engine;

interface BoundaryNode<T> extends Node {
	public final fallback:(payload:T) -> Node;
	public final child:Node;
}

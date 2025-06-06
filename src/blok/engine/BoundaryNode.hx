package blok.engine;

interface BoundaryNode<T> extends Node {
	public final fallback:(error:T) -> Node;
	public final child:Node;
}

package blok;

interface VNode {
	public final type:UniqueId;
	public final key:Null<Key>;
	public function getProps<T:{}>():T;
	public function createView():View;
}

package blok;

class Slot {
	public final host:PrimitiveView;
	public final index:Int;
	public final previous:Null<View>;

	public function new(host, index, previous) {
		this.host = host;
		this.index = index;
		this.previous = previous;
	}

	public function changed(other:Slot) {
		return index != other.index;
	}
}

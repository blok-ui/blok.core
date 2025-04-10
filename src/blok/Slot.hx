package blok;

class Slot {
	public final index:Int;
	public final previous:Null<View>;

	public function new(index, previous) {
		this.index = index;
		this.previous = previous;
	}

	public function changed(other:Slot) {
		return index != other.index;
	}
}

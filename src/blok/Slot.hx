package blok;

class Slot {
	public final parent:View;
	public final index:Int;
	public final previous:Null<View>;

	public function new(parent, index, previous) {
		this.parent = parent;
		this.index = index;
		this.previous = previous;
	}

	public function changed(other:Slot) {
		return index != other.index;
	}
}

package blok.macro;

interface Builder {
	public final priority:BuilderPriority;
	public function apply(builder:ClassBuilder):Void;
}

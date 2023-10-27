package blok.macro.build;

interface Builder {
  public final priority:BuilderPriority;
  public function apply(builder:ClassBuilder):Void;
}

package blok.macro.build;

interface Builder {
  public function parse(builder:ClassBuilder):Void;
  public function apply(builder:ClassBuilder):Void;
}

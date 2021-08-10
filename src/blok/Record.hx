package blok;

@:autoBuild(blok.RecordBuilder.build())
interface Record {
  public function hashCode():Int;
}

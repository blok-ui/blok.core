package blok.core;

interface Cursor<RealNode> {
  public function insert(node:RealNode):Bool;
  public function step():Bool;
  public function delete():Bool;
  public function current():RealNode;
}

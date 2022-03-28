package blok.ui;

interface HydrationCursor {
  public function current():Dynamic;
  public function currentChildren():HydrationCursor;
  public function next():Void;
  public function move(current:Dynamic):Void;
}

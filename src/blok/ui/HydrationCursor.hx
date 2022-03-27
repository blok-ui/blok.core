package blok.ui;

interface HydrationCursor {
  public function current():Dynamic;
  public function next():Void;
  public function getCurrentChildren():HydrationCursor;
}

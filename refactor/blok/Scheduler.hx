package blok;

interface Scheduler {
  public function schedule(item:()->Void):Void;
}

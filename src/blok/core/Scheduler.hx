package blok.core;

interface Scheduler {
  public function schedule(item:()->Void):Void;
}

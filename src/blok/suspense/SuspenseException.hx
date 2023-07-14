package blok.suspense;

import haxe.Exception;

class SuspenseException extends Exception {
  public final task:Task<Any, Any>;

  public function new(task) {
    super('Unhandled suspension');
    this.task = task;
  }
}

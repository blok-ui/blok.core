package blok.exception;

import haxe.Exception;

class WrappedException extends BlokException {
  public final target:Exception;

  public function new(target:Exception, widget) {
    super(target.message, widget, target);
    this.target = target;
  }
}

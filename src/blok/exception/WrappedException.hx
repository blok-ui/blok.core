package blok.exception;

import haxe.Exception;

class WrappedException extends BlokException {
  public final target:Exception;

  public function new(target:Exception, component) {
    super(target.message, component, target);
    this.target = target;
  }
}

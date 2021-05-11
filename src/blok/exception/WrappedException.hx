package blok.exception;

import haxe.Exception;

class WrappedException extends BlokException {
  public function new(target:Exception, component) {
    super(target.message, component, target);
  }
}
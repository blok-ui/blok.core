package blok.exception;

import haxe.Exception;

class NoContextException extends Exception {
  public function new() {
    super('Attempted to use `context` before it was registered');
  }
}

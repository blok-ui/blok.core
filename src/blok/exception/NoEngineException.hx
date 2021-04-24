package blok.exception;

import haxe.Exception;

class NoEngineException extends Exception {
  public function new() {
    super('No engine was registered');
  }
}

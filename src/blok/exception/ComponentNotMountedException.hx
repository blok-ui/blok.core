package blok.exception;

import haxe.Exception;

class ComponentNotMountedException extends Exception {
  public function new() {
    super('Attempted to render or update a component that has not been mounted');
  }
}
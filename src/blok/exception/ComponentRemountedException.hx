package blok.exception;

import haxe.Exception;

class ComponentRemountedException extends Exception {
  public function new() {
    super('Attempted to re-mount a component that was already mounted');
  }
}
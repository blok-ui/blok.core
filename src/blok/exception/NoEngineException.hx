package blok.exception;

class NoEngineException extends BlokException {
  public function new(component) {
    super('No engine was registered', component);
  }
}

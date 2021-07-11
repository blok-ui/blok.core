package blok.exception;

class NoEngineException extends BlokException {
  public function new(component) {
    super('Component does not have an Engine.', component);
  }
}

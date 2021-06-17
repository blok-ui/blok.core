package blok.exception;

class NoProviderException extends BlokException {
  public function new(component) {
    super('Could not consume context as this is not a child of a Provider', component);
  }
}
package blok.exception;

class NoProviderException extends BlokException {
  public function new(component) {
    super('Could consume context as this is not a child of a Provider', component);
  }
}
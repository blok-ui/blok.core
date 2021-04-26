package blok.exception;

class ComponentNotMountedException extends BlokException {
  public function new(component) {
    super('Attempted to render or update a component that has not been mounted', component);
  }
}
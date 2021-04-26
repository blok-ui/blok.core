package blok.exception;

class ComponentRemountedException extends BlokException {
  public function new(component) {
    super('Attempted to re-mount a component that was already mounted', component);
  }
}
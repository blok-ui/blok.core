package blok.exception;

class ComponentIsRenderingException extends BlokException {
  public function new(component) {
    super('Cannot update or render while a component is already rendering.', component);
  }
}
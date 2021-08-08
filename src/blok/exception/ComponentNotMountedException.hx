package blok.exception;

class WidgetNotMountedException extends BlokException {
  public function new(widget) {
    super('Attempted to render or update a widget that has not been mounted', widget);
  }
}
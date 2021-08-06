package blok.exception;

class WidgetRemountedException extends BlokException {
  public function new(widget) {
    super('Attempted to re-mount a widget that was already mounted', widget);
  }
}
package blok.exception;

class WidgetIsUpdatingException extends BlokException {
  public function new(widget) {
    super('Cannot update a widget while it is already updating.', widget);
  }
}
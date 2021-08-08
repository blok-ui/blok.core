package blok.exception;

class WidgetIsRenderingException extends BlokException {
  public function new(widget) {
    super('Cannot update or render while a widget is already rendering.', widget);
  }
}
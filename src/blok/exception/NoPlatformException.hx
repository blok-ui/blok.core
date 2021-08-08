package blok.exception;

class NoPlatformException extends BlokException {
  public function new(widget) {
    super('No Platform exists in the widget tree.', widget);
  }
}

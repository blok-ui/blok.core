package blok.ui;

enum abstract WidgetLifecycle(Int) {
  var WidgetPending;
  var WidgetValid;
  var WidgetInvalid;
  var WidgetUpdating;
  var WidgetDisposed;
}
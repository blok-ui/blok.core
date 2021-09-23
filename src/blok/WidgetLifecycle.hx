package blok;

import haxe.Exception;

enum WidgetLifecycle {
  WidgetPending;
  WidgetValid;
  WidgetInvalid;
  WidgetUpdating;
  WidgetRecovering(e:Exception);
  WidgetDisposed;
}
package blok;

import haxe.Exception;

enum WidgetLifecycle {
  WidgetPending;
  WidgetValid;
  WidgetInvalid;
  WidgetRendering;
  WidgetRecovering(e:Exception);
  WidgetDisposed;
}
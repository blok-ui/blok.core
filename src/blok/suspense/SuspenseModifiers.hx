package blok.suspense;

import blok.ui.*;

function inSuspense(child:Child, fallback:()->Child, ?options:{
  ?onComplete:()->Void,
  ?onSuspended:()->Void,
  ?overridable:Bool
}) {
  return SuspenseBoundary.node({
    child: child,
    fallback: fallback,
    onComplete: options?.onComplete,
    onSuspended: options?.onSuspended,
    overridable: options?.overridable
  });
}

package blok.boundary;

import blok.ui.*;

function inErrorBoundary(child:Child, fallback) {
  return ErrorBoundary.node({
    child: child,
    fallback: fallback
  });
}

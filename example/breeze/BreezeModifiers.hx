package breeze;

import Breeze;
import blok.signal.Signal;
import blok.ui.Child;

using breeze.BreezeModifiers;

function styles(child:Child, ...classes:ClassName) {
  return BreezeStyles.node({
    styles: ClassName.ofArray(classes),
    child: child
  });
}

function observedStyles(child:Child, styles:ReadonlySignal<ClassName>) {
  return BreezeStyles.node({
    styles: styles, 
    child: child
  });
}

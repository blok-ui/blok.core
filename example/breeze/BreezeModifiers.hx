package breeze;

import Breeze;
import blok.html.HtmlAttributes;
import blok.html.VNativeBuilder;
import blok.signal.Computation;

function styles<Props:GlobalAttr>(builder:VNativeBuilder<Props>, ...classes:ClassName) {
  builder.props.className = switch builder.props.className {
    case null: Breeze.compose(...classes);
    case name: new Computation(() -> name() + ' ' + Breeze.compose(...classes));
  }
  return builder;
}

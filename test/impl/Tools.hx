package impl;

import blok.ui.*;

class Tools {
  public static function stringifyWidget(comp:Widget) {
    var text:Array<String> = [];
    for (child in comp.getChildConcreteManagers()) text = text.concat(cast child.toConcrete());
    return text.filter(t -> t.length > 0).join(' ');
  }
}

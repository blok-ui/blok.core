package blok.tools;

import haxe.DynamicAccess;

class ObjectTools {
  static final EMPTY = {};
  
  public static function diffObject(
    oldProps:DynamicAccess<Dynamic>,
    newProps:DynamicAccess<Dynamic>,
    apply:(key:String, oldValue:Dynamic, newValue:Dynamic)->Void
  ):Int {
    if (oldProps == newProps) return 0;

    var changed:Int = 0;
    var keys = (if (newProps == null) {
      newProps = EMPTY;
      oldProps;
    } else if (oldProps == null) {
      oldProps = EMPTY;
      newProps;
    } else {
      var ret = newProps.copy();
      for (key in oldProps.keys()) ret[key] = true;
      ret;
    }).keys();

    for (key in keys) switch [ oldProps[key], newProps[key] ] {
      case [ a, b ] if (a == b):
      case [ a, b ]: 
        apply(key, a, b);
        changed++;
    }

    return changed;
  }
}

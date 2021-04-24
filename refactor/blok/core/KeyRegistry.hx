package blok.core;

import haxe.ds.Map;

class KeyRegistry implements Registry<Key, Component> {
  var strings:Map<String, Component>;
  var objects:Map<{}, Component>;

  public function new() {}

  public function put(?key:Key, value:Component):Void {
    if (key == null) {
      throw 'Key cannot be null';
    } if (key.isString()) {
      if (strings == null) strings = [];
      strings.set(cast key, value);
    } else {
      if (objects == null) objects = [];
      objects.set(key, value);
    }
  }

  public function pull(?key:Key):Component {
    if (key == null) return null;
    var map:Map<Dynamic, Component> = if (key.isString()) strings else objects;
    if (map == null) return null;
    var out = map.get(key);
    map.remove(key);
    return out;
  }

  public function exists(key:Key):Bool {
    var map:Map<Dynamic, Component> = if (key.isString()) strings else objects;
    if (map == null) return false;
    return map.exists(key);
  }

  public function each(cb:(value:Component)->Void) {
    if (strings != null) for (v in strings) cb(v);
    if (objects != null) for (v in objects) cb(v);
  }
}

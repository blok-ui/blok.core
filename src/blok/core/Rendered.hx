package blok.core;

// @:forward(iterator, keyValueIterator)
// abstract Rendered(Map<ComponentType<Dynamic, Dynamic>, ComponentTypeRegistry>) {
//   public function new() {
//     this = [];
//   }

//   public var length(get, never):Int;
//   function get_length() {
//     return [ for (k in this.keys()) k ].length;
//   }

//   public function hasRegistry(type) {
//     return this.exists(type);
//   }

//   public function getRegistry(type:ComponentType<Dynamic, Dynamic>):ComponentTypeRegistry {
//     if (!this.exists(type)) {
//       this.set(type, new ComponentTypeRegistry());
//     }
//     return this.get(type);
//   }

//   public function addChild(type, key, component) {
//     getRegistry(type).put(key, component);
//   }
// }

@:allow(blok)
@:allow(blok.core)
class Rendered {
  final children:Array<Component>;
  final types:Map<ComponentType<Dynamic, Dynamic>, ComponentTypeRegistry>;

  public function new() {
    children = [];
    types = [];
  }

  public var length(get, never):Int;
  function get_length() return children.length;

  public function hasRegistry(type) {
    return types.exists(type);
  }

  public function getRegistry(type:ComponentType<Dynamic, Dynamic>):ComponentTypeRegistry {
    if (!types.exists(type)) {
      types.set(type, new ComponentTypeRegistry());
    }
    return types.get(type);
  }

  public function addChild(type, key, component) {
    children.push(component);
    getRegistry(type).put(key, component);
  }
}
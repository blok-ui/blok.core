package blok.core;

@:forward
abstract UniqueId(Int) to Int {
  static var uid:Int = 0;

  inline public function new() {
    this = uid++;
  }
}

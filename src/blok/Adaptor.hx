package blok;

interface Adaptor {
	public function schedule(effect:() -> Void):Void;
	public function scheduleEffect(effect:() -> Void):Void;
	public function createPrimitive(name:String, attrs:{}):Dynamic;
	public function createPlaceholderPrimitive():Dynamic;
	public function createTextPrimitive(text:String):Dynamic;
	public function createContainerPrimitive(attrs:{}):Dynamic;
	public function createCursor(object:Dynamic):Cursor;
	public function updateTextPrimitive(object:Dynamic, value:String):Void;
	public function updatePrimitiveAttribute(object:Dynamic, name:String, oldValue:Null<Dynamic>, value:Dynamic, ?isHydrating:Bool):Void;
	public function insertPrimitive(object:Dynamic, slot:Null<Slot>, findParent:() -> Dynamic):Void;
	public function movePrimitive(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:() -> Dynamic):Void;
	public function removePrimitive(object:Dynamic, slot:Null<Slot>):Void;
}

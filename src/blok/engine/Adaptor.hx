package blok.engine;

interface Adaptor {
	public function schedule(effect:() -> Void):Void;
	public function scheduleEffect(effect:() -> Void):Void;
	public function createPrimitive(tag:String):Any;
	public function createTextPrimitive(text:String):Any;
	public function createContainerPrimitive():Any;
	public function updateTextPrimitive(primitive:Any, value:String):Void;
	public function updatePrimitiveAttribute(primitive:Any, name:String, oldValue:Null<Any>, value:Any, ?isHydrating:Bool):Void;
	public function checkPrimitiveType(primitive:Any, type:String):Result<Any>;
	public function checkText(primitive:Any):Result<Any>;
	public function children(primitive:Any):Cursor;
	public function siblings(primitive:Any):Cursor;
}

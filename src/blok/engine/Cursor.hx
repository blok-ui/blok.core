package blok.engine;

interface Cursor {
	public function next():Void;
	public function current():Maybe<Any>;
	public function insert(primitive:Any):Result<Any>;
	public function remove(primitive:Any):Result<Any>;
}

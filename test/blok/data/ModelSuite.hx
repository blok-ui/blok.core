package blok.data;

class ModelSuite extends Suite {
	// @todo
}

class SimpleModel extends Model {
	@:value public final first:String;
	@:signal public final last:String;
	@:computed public final full:String = first + last();
}

class SimpleUnserializableModel extends UnserializableModel {
	@:value public final first:String;
	@:signal public final last:String;
	@:computed public final full:String = first + last();
}

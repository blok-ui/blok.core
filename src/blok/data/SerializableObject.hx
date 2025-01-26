package blok.data;

@:autoBuild(blok.data.ObjectBuilder.buildWithJsonSerializer())
abstract class SerializableObject {
	abstract public function toJson():Dynamic;
}

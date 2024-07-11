package blok.html;

private final tags:Map<String, UniqueId> = [];

@:deprecated("Use blok.ui.Primitive.getTypeForTag")
inline function getTypeForTag(tag:String) {
	return blok.ui.Primitive.getTypeForTag(tag);
}

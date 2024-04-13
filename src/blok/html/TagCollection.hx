package blok.html;

private final tags:Map<String, UniqueId> = [];

function getTypeForTag(tag:String) {
	var id = tags.get(tag);
	if (id == null) {
		id = new UniqueId();
		tags.set(tag, id);
	}
	return id;
}

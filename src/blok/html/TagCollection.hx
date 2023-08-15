package blok.html;

final Tags:Map<String, UniqueId> = [];

function getTypeForTag(tag:String) {
  var id = Tags.get(tag);
  if (id == null) {
    id = new UniqueId();
    Tags.set(tag, id);
  }
  return id;
}

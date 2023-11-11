package blok.html;

@:build(blok.html.TagBuilder.build('blok.html.HtmlTags'))
class Html {
  @:skip static final tags:Map<String, UniqueId> = [];

  @:skip public static function getTypeForTag(tag:String) {
    var id = tags.get(tag);
    if (id == null) {
      id = new UniqueId();
      tags.set(tag, id);
    }
    return id;
  }
  
  @:skip macro public static function view(expr);
}

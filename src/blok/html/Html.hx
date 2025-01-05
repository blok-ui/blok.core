package blok.html;

@:build(blok.html.TagBuilder.build('blok.html.HtmlTags'))
class Html {
	@:skip macro public static function view(expr);
}

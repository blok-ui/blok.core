package blok.html;

@:build(blok.html.HtmlAttributeNameBuilder.build())
enum abstract HtmlAttributeName(String) from String to String {}

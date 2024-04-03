package blok.html;

@:build(blok.html.HtmlEventNameBuilder.build())
enum abstract HtmlEventName(String) to String {}

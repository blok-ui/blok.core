package blok;

@:build(blok.core.ComponentBuilder.build((_:js.html.Node)))
@:autoBuild(blok.core.ComponentBuilder.autoBuild((_:js.html.Node)))
class Component implements blok.core.Component<js.html.Node> {}

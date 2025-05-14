package blok.engine;

class TextNode implements Node {
	public final key:Null<Key>;
	public final content:String;

	public function new(content, ?key) {
		this.content = content;
		this.key = key;
	}

	public function matches(other:Node):Bool {
		return (other is TextNode && other.key == key);
	}

	public function createView(parent:Maybe<View>, adaptor:Adaptor):View {
		return new TextView(parent, this, adaptor);
	}
}

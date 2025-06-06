package blok;

import blok.engine.*;
import blok.engine.BoundaryView;
import blok.html.Html;

// @todo: This is a VERY early stab at this.
//
// Ideally using this node will also insert some kind of console tool when used on the client?
class DebugBoundary implements BoundaryNode<ViewError> {
	@:fromMarkup
	@:noUsing
	public static function node(props:{
		@:children public final child:Node;
		public final ?key:Key;
		public final ?fallback:(error:ViewError) -> Node;
	}) {
		return new DebugBoundary(props.child, props.fallback, props.key);
	}

	public final key:Null<Key>;
	public final child:Node;
	public final fallback:(error:ViewError) -> Node;

	public function new(child, ?fallback:(error:ViewError) -> Node, ?key) {
		this.child = child;
		this.fallback = fallback ?? defaultFallback;
		this.key = key;
	}

	public function createView(parent:Maybe<View>, adaptor:Adaptor):View {
		return new BoundaryView(parent, this, adaptor, {
			decode: (boundary, target, error) -> {
				if (error is ViewError) return Some(cast error);
				return None;
			},
			recover: (boundary, target, error) -> Future.immediate(Ignore)
		});
	}

	public function matches(other:Node):Bool {
		return other is DebugBoundary && other.key == key;
	}
}

private function defaultFallback(error:ViewError) {
	var title:String = switch error {
		case ViewAlreadyExists(_): 'View already exists';
		case InsertionFailed(_, _): 'View insertion failed';
		case IncorrectNodeType(_, _): 'Incorrect node type';
		case HydrationMismatch(_, _, _): 'Hydration mismatch';
		case NoNodeFoundDuringHydration(_, _): 'Hydration mismatch';
		case CausedException(_, _): 'Exception';
	}

	return Html.view(<div style="display:flex;background-color:red;color:white;padding:5px;border-radius:3px">
		<header>
			<h3>"Debug Error: " title</h3>
		</header>
		<div>
			{switch error {
				case ViewAlreadyExists(view):
					<pre>{buildTree(view)}</pre>;
				case InsertionFailed(view, message):
					<>
						<p>message</p>
						<pre>{buildTree(view)}</pre>
					</>;
				case IncorrectNodeType(view, node):
					<>
						<p>"Unexpected node of type " {Type.getClassName(Type.getClass(node))}</p> 
						<pre>{buildTree(view)}</pre>
					</>;
				case HydrationMismatch(view, expected, actual):
					<>
						<p>"Expected node: " {Std.string(expected)} "but was" {Std.string(actual)}</p>
						<pre>{buildTree(view)}</pre>
					</>;
				case NoNodeFoundDuringHydration(view, expected):
					<pre>{buildTree(view)}</pre>;
				case CausedException(view, exception):
					<pre>{buildTree(view)}</pre>;
			}}
		</div>
	</div>);
}

private function buildTree(view:View) {
	return '';
}

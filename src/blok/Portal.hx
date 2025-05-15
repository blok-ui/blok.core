package blok;

import blok.engine.*;

typedef PortalProps = {
	public final target:Dynamic;
	@:children public final child:Child;
	public final ?key:Key;
}

@:forward
@:forward.new
abstract Portal(PortalNode) to Node to Child {
	@:fromMarkup
	@:noUsing
	public inline static function node(props:PortalProps) {
		return new PortalNode(props.target, props.child, props.key);
	};

	public inline static function wrap(target:Dynamic, child:Child, ?key) {
		return node({
			target: target,
			child: child,
			key: key
		});
	}
}

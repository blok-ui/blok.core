package blok;

import blok.engine.*;

@:forward
abstract Fragment(FragmentNode) from FragmentNode to Node to Child {
	@:fromMarkup
	@:noCompletion
	@:noUsing
	public static function fromMarkup(props:{
		@:children final children:Children;
	}) {
		return of(props.children);
	}

	@:from
	public static function of(children:Children):Fragment {
		return new FragmentNode(children);
	}
}

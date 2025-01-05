package blok.html;

import blok.html.HtmlAttributes;
import blok.html.HtmlEvents;
import blok.signal.Computation;
import blok.signal.Signal;

using Reflect;

abstract VHtmlPrimitive(VPrimitiveView) to Child to VPrimitiveView to VNode {
	public function new(type, tag, ?props, ?children, ?key) {
		this = new VPrimitiveView(type, tag, props, children, key);
	}

	public function attr(name:AttributeName<GlobalAttr>, value:ReadOnlySignal<String>) {
		if (name == 'class' && this.props.hasField('class')) {
			var prev:ReadOnlySignal<String> = this.props.field(name);
			this.props.setField(name, new Computation(() -> prev() + ' ' + value()));
			return abstract;
		}

		this.props.setField(name, value);
		return abstract;
	}

	public function on(event:AttributeName<HtmlEvents>, handler:ReadOnlySignal<EventListener>) {
		this.props.setField(event, handler);
		return abstract;
	}

	public function child(...children:Child) {
		for (child in children) if (child.type == Fragment.componentType) {
			abstract.child(...child.getProps().children);
		} else {
			this.children.push(child);
		}
		return abstract;
	}

	@:to
	public inline function toChildren():Children {
		return node();
	}

	@:to
	public inline function node():Child {
		return this;
	}
}

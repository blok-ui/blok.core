package blok.html;

import blok.signal.Computation;
import blok.html.HtmlEvents;
import blok.signal.Signal;

using Reflect;

abstract VHtmlPrimitive(VPrimitiveView) to Child to VPrimitiveView to VNode {
	public function new(type, tag, ?props, ?children, ?key) {
		this = new VPrimitiveView(type, tag, props, children, key);
	}

	public function attr(name:HtmlAttributeName, value:ReadOnlySignal<String>) {
		if (this.props.hasField(HtmlAttributeName.ClassName) && name == HtmlAttributeName.ClassName) {
			var prev:ReadOnlySignal<String> = this.props.field(name);
			this.props.setField(name, new Computation(() -> prev() + ' ' + value()));
			// this.props.setField(name, prev.map(prev -> prev + ' ' + value()));
			return abstract;
		}

		this.props.setField(name, value);
		return abstract;
	}

	public inline function on(event:HtmlEventName, handler:ReadOnlySignal<EventListener>) {
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

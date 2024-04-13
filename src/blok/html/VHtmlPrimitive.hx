package blok.html;

import blok.html.HtmlEvents;
import blok.signal.Signal;
import blok.ui.*;

using Reflect;

abstract VHtmlPrimitive(VPrimitive) to Child to VPrimitive to VNode {
	public function new(type, tag, ?props, ?children, ?key) {
		this = new VPrimitive(type, tag, props, children);
	}

	public inline function attr(name:HtmlAttributeName, value:ReadOnlySignal<String>) {
		if (this.props.hasField(HtmlAttributeName.ClassName) && name == ClassName) {
			var prev:ReadOnlySignal<String> = this.props.field(name);
			this.props.setField(name, prev.map(prev -> prev + ' ' + value()));
			return abstract;
		}

		this.props.setField(name, value);
		return abstract;
	}

	public inline function on(event:HtmlEventName, handler:ReadOnlySignal<EventListener>) {
		this.props.setField('on' + event, handler);
		return abstract;
	}

	public inline function child(child:Child) {
		this.children.push(child);
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

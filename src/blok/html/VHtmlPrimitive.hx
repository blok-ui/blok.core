package blok.html;

import blok.ui.Fragment.VFragment;
import blok.html.HtmlEvents;
import blok.signal.Signal;
import blok.ui.*;

using Reflect;

abstract VHtmlPrimitive(VPrimitive) to Child to VPrimitive to VNode {
	public function new(type, tag, ?props, ?children, ?key) {
		this = new VPrimitive(type, tag, props, children);
	}

	public inline function attr(name:HtmlAttributeName, value:ReadOnlySignal<String>) {
		if (this.props.hasField(HtmlAttributeName.ClassName) && name == HtmlAttributeName.ClassName) {
			var prev:ReadOnlySignal<String> = this.props.field(name);
			this.props.setField(name, prev.map(prev -> prev + ' ' + value()));
			return abstract;
		}

		this.props.setField(name, value);
		return abstract;
	}

	public inline function on(event:HtmlEventName, handler:ReadOnlySignal<EventListener>) {
		this.props.setField(event, handler);
		return abstract;
	}

	public inline function child(...children:Child) {
		for (child in children) switch Std.downcast(child, VFragment) {
			case null: this.children.push(child);
			case fragment: abstract.child(...fragment.unwrap());
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

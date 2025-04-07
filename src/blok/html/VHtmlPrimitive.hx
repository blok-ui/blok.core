package blok.html;

import blok.diffing.Key;
import blok.html.HtmlAttributes;
import blok.html.HtmlEvents;
import blok.signal.Computation;
import blok.signal.Signal;

using Reflect;

class VHtmlPrimitive extends VPrimitiveView {
	public function attr(name:AttributeName<GlobalAttributes>, value:ReadOnlySignal<String>) {
		if (name == 'class' && props.hasField('class')) {
			var prev:ReadOnlySignal<String> = props.field(name);
			props.setField(name, new Computation(() -> prev() + ' ' + value()));
			return this;
		}

		props.setField(name, value);
		return this;
	}

	public function on(event:AttributeName<HtmlEvents>, handler:ReadOnlySignal<EventListener>) {
		props.setField(event, handler);
		return this;
	}

	public function withKey(key:Key) {
		props.setField('key', key);
		return this;
	}

	public function child(...children:Child) {
		for (child in children) if (child.type == Fragment.componentType) {
			this.child(...child.getProps().children);
		} else {
			this.children.push(child);
		}
		return this;
	}

	public inline function node():Child {
		return this;
	}
}

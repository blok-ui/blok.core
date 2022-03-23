package blok.ui;

import blok.core.UniqueId;

class ComponentWidget<Props:{}> extends Widget {
  public final props:Props;
  final type:UniqueId;
  final factory:(widget:ComponentWidget<Props>)->Component;

  public function new(type, props, factory, key) {
    super(key);
    this.props = props;
    this.type = type;
    this.factory = factory;
  }

	public function getWidgetType():UniqueId {
		return type;
	}

	public function createElement():Element {
		return factory(this);
	}

  public function withProperties(props:Props) {
    return new ComponentWidget(type, props, factory, key);
  }
}

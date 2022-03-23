package blok.ui;

import blok.core.UniqueId;

using blok.core.ObjectTools;

class ComponentWidget<Props:{}> extends Widget {
  public final props:Props;
  final type:UniqueId;
  final comparator:(oldWidget:ComponentWidget<Props>, newWidget:ComponentWidget<Props>)->Bool;
  final factory:(widget:ComponentWidget<Props>)->Component;

  public function new(type, props, comparator, factory, key) {
    super(key);
    this.props = props;
    this.type = type;
    this.comparator = comparator;
    this.factory = factory;
  }

  public function getWidgetType():UniqueId {
    return type;
  }

  public function createElement():Element {
    return factory(this);
  }

  override function shouldBeUpdated(newWidget:Widget):Bool {
    return super.shouldBeUpdated(newWidget);
  }

  public function hasChanged(newWidget:Widget) {
    return comparator(this, cast newWidget);
  }

  public function withProperties(props:Props) {
    return new ComponentWidget(
      type,
      this.props.merge(props),
      comparator,
      factory,
      key
    );
  }
}

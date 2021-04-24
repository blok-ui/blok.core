package blok.dom;

import js.html.Text;

class TextType {
  public static function create(props:{ content:String }) {
    return new NativeComponent(new Text(props.content), {}, false);
  }

  public static function update(component:NativeComponent<{}>, props:{ content:String }) {
    if (component.node.textContent != props.content) component.node.textContent = props.content;
  }
}

package blok;

import js.html.Text;

class TextType {
  public static function create(props:{ content:String }) {
    return new NativeComponent(new Text(props.content), {}, false);
  }

  public static function update(component:NativeComponent<{}>, props:{ content:String }) {
    var n:Text = cast component.node;
    if (n.textContent != props.content) n.textContent = props.content;
  }
}

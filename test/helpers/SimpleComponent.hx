package helpers;

import blok.Html;
import blok.Component;

class SimpleComponent extends Component {
  @prop var className:String;
  @prop var content:String;
  
  override function render(context) {
    return Html.h('p', { className: className }, [ Html.text(content) ]);
  }
}

package blok.framework.platform;

class HtmlRootElement extends RootElement {
  public function resolveRootObject():Dynamic {
    return (cast widget:HtmlRootWidget).el;
  }
}

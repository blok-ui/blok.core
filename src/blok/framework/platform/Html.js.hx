package blok.framework.platform;

class Html {
  public static inline function create(tag, attrs, children) {
    return new HtmlObjectWidget(tag, attrs, children);
  }

  public static inline function text(content:String) {
    return new HtmlTextWidget(content);
  }
}

Blok Core
=========

Blok's core functionality.

```haxe
using Blok;

class Foo extends Component {
  @prop var foo:String;

  public function render() {
    return Html.div({ className: 'fooable' },
      Html.text(foo),
      Html.span({}, Html.text('etc'))
    );
  }
}
```

> More to come

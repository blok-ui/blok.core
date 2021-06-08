Blok Core
=========

Blok's core functionality.

```haxe
using Blok;

class Foo extends Component {
  @prop var foo:String;

  public function render() {
    return Html.div({
      attrs: {
        className: 'fooable'
      },
      children: [ Html.text(foo) ]
    });
  }
}
```

> More to come

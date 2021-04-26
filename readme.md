Blok Core
=========

Blok's core functionality.

Basics
------

Blok's API should be very familiar if you've used React (or anything like it). 

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

Services, Providers and Context
-------------------------------



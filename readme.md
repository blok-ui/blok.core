Blok Core
=========

Blok is a reactive UI framework built for the web but flexible enough to be used elsewhere.

Getting Started
---------------

Blok is not yet on haxelib, but you can install it using [Lix](https://github.com/lix-pm/lix.client).

```
lix install gh:blok-ui/blok.core
```

To get a sense of how Blok works, try creating a simple counter app:

```haxe
import blok.ui.*;
import blok.html.*;

function main() {
  Client.mount(
    js.Browser.document.getElementById('root'),
    () -> Counter.node({})
  )
}

class Counter extends Component {
  @:signal final count:Int = 0;

  function render() {
    return Html.div({},
      Html.div({}, count),
      Html.button({
        onClick: _ -> count.update(count -> count > 0 ? count - 1 : 0)
      }, '-')
      Html.button({
        onClick: _ -> count.update(count -> count + 1)
      }, '+')
    );
  }
}
```

> Coming soon: an explanation of what's going on up there

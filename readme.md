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
import blok.html.Html;

function main() {
  Client.mount(
    js.Browser.document.getElementById('root'),
    () -> Counter.node({})
  )
}

class Counter extends Component {
  @:signal final count:Int = 0;

  @:action
  function decrement(_:blok.html.HtmlEvents.Event) {
    count.update(count -> count > 0 ? count - 1 : 0);
  }

  function render() return Html.view(<div>
    <div>count</div>
    <button onClick=decrement>"-"</button>
    <button onClick={ _ -> count.update(count -> count + 1)}>"+"</button>
  </div>);
}
```

Signals
-------

> Note: this section is a work in progress.

Blok is a *reactive framework*. When a value changes, it automatically tracks it and updates as needed.

The core mechanism to make this possible are *Signals*. Blok's implementation is based heavily on [Preact's Signals](https://github.com/preactjs/signals) and on the implementation used by [Angular](https://github.com/angular/angular/tree/d32767da06dd3a05930f177fd14a9fed49cbb8d1/packages/core/primitives/signals).

Generally you won't be creating Signals directly (we'll get into why in the Components and Models sections below), but it's useful to understand what's going on with them. Lets set up a simple example:

```haxe
var foo = new blok.signal.Signal('Foo');
```

> Note: `blok.signal.Signal` is an abstract, so the above could also be written `var foo:blok.signal.Signal<String> = 'foo'`. This is a handy Haxe feature that Blok makes extensive use of to make authoring VNodes more ergonomic.

Reading and writing the value of `foo` can be done as follows:

```haxe
// Call it like a function (recommended):
trace(foo());
// Or use the getter:
trace(foo.get());

// Use `set` to update the value:
foo.set('bar');
// ...or `update` to also get access to the current value:
foo.update(value -> 'foo' + value);
```

None of this is particularly interesting on its own, but it becomes much more useful when we pair our Signal with an Observer:

```haxe
import blok.signal.*;

function main() {
  var foo:Signal<String> = 'foo';
  // Note: generally you'll be using `Observer.track`, however 
  // we need to call `Observer.root` here to set up our observable 
  // scope correctly. You'll never need to do this inside Components.
  var root = Observer.root(() -> {
    trace(foo());
  });

  foo.update(value -> value + 'bar');
  foo.set('done');
}
```

If you run this code, you'll notice something: it traces "foo", "foobar" and finally "done". This is the key to the power of signals: by simply by calling `foo()` inside our `Observer` we've subscribed to it and will re-run every time `foo` changes.

> Note: if you want to get the value of a Signal *without* subscribing to it, you can use the `peek` method (e.g. `foo.peek()`).

> Todo: There are still a few more things to explain, mainly `Computation` and `Action`.

Components
----------

> Note: this section is a work in progress.

Blok apps are built out of Components, and they're the primary thing you'll be using. Let's bring back our Counter example:

> Note: Blok *does* have a JSX-like DSL, but it's still very experimental so we're going to be sticking to function calls here. You can use either method in your apps.

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
  @:attribute final increment:Int = 1;
  @:signal final count:Int = 0;
  @:computed final className = 'counter-${count()}';

  @:action
  function decrement(_:blok.html.HtmlEvents.Event) {
    count.update(count -> count > 0 ? count - increment : 0);
  }

  function render() {
    return Html.div({ className: className },
      Html.div({}, count),
      Html.button({ onClick: decrement }, '-'),
      Html.button({ onClick: _ -> count.update(count -> count + increment) }, '+')
    );
  }
}
```

In our `Counter` class, you'll note that we have a bunch of class fields marked with metadata. These are fairly self-explanatory, but let's go over them one by one.

> Todo: ...I'll get to that.

> Todo: Also explain @:resource fields and how they work with SuspenseBoundaries.

Models
------

> Note: this section is a work in progress.


Blok Core
=========

Blok's core functionality.

> Note: Blok is currently a fun personal project and something that changes a lot. Most of the surface API is pretty stable, but use it at your own risk. Things may change at any moment.

Getting Started
---------------

Generally, you'll want to use one of Blok's Platforms instead of using `blok.core` directly. Currently, there are two platforms:

| Platform | Target |
|----------|--------|
| [blok.platform.dom](https://github.com/blok-ui/blok.platform.dom) | Web                       |
| [blok.platform.static](https://github.com/blok-ui/blok.platform.static) | Servers / Html Generators |

Blok is designed to be flexible, so there are plans for more platforms.

Blok also has some other packages that provide more functionality:

| Repository | Provides |
|------------|----------|
| [blok.core.foundation](https://github.com/blok-ui/blok.core.foundation) | Routing, Portals |
| [blok.gen](https://github.com/blok-ui/blok.gen) | Static site generation |

Using Blok
----------

Blok is a *declarative UI framework*, similar in concept to React and Flutter. It takes a tree of *Widgets* (or "VNodes", in React parlance) and uses them to build and re-build a UI. Blok is designed to be flexible, so the actual rendering of the UI is handled by a `blok.ui.Platform` (like the one that targets the DOM) which just needs a few simple functions to be implemented.

Regardless of the platform, the main class you'll be extending is the `blok.ui.Component`. For these examples, let's assume we're using a simple platform that gives us a low-level "TextWidget". 

```haxe
import blok.ui.Widget;
import blok.ui.Component;

class Foo extends Component {
  @prop var foo:String;

  function render():Widget {
    return new TextWidget(foo);
  }
}
```

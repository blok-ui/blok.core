Blok Core
=========

Blok's core functionality.

> Note: Blok is currently a fun personal project and something that changes a lot. Most of the surface API is pretty stable, but use it at your own risk. Things may change at any moment.

Using Blok
----------

Generally, you'll want to use one of Blok's Platforms instead of using `blok.core` directly. Currently, there are two platforms:

| Platform             | Target                    |
|----------------------|---------------------------|
| [blok.platform.dom](https://github.com/blok-ui/blok.platform.dom) | Web                       |
| [blok.platform.static](https://github.com/blok-ui/blok.platform.static) | Servers / Html Generators |

Blok is designed to be flexible, so there are plans for more platforms.

Blok also provides some useful base components (like Routers and Portals) which are available here:

| Repository | Provides |
|------------|----------|
| [blok.core.foundation](https://github.com/blok-ui/blok.core.foundation) | Routing, Portals, Suspension (async rendering) |


Packages
--------

The core package for blok currently consists of several sub-packages (which could be split off into their own repositories at some point in the future). Here they are, in no particular order:

- blok.core: Utility classes and basic interfaces that don't fit anywhere else.
- blok.exception: Various exceptions that might be thrown during the lifetime of a Blok app (note: this is currently in flux -- expect this to get more useful).
- blok.ui: The core UI framework for Blok -- Components, VNodes and Diffing all live here.
- blok.context: The Context API for Blok, allowing the passing of services around an app (it's Dependency Injection, basically).
- blok.data: Tools for immutable data and JSON serialization (sill a work in progress).
- blok.state: Classes that provide simple reactivity to your app.
- blok.macro: Macro tools used for much of Blok's API; provides a more consistent way to use metadata to generate code. 

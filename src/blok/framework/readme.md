Note: This is a pretty close copy of Flutter's "framework.dart" file. It's missing a lot of the stuff that makes Blok work (like Effects and the way we make sure Components don't render too many times), and is only to get a sense of how Flutter does things.

I think this *is* a better way of doing things, but DO NOT USE this code directly. Figure out how Google is doing things and go from there.

Things we'll change:

- `activate` and `deactivate` don't really mean anything for us. Replace with a simple `dispose`?
- `effects` should always be passed to the `update` method somehow -- we'll probably have to depend on `Platform` batching things.
- We need a name for the `RenderObject`. Maybe we can just refer to them as `Objects`?
- Also (and this is already true) we don't have `StatefulWidgets`. Instead, State is controlled directly by a `Component` (which is a subclass of `Element`, not `Widget`) which is built by a generic `ComponentWidget`. We also use macros (already present) to update state, not a `setState` method. The main issue we have now is how we invalidate Elements -- we'll need to do a bit more work.
- We might want to rework inheritance to be a bit closer to Flutter, rather than the Context system we have now. Not sure about that though. 
- The API is a bit too OOP for my taste -- there are a LOT of `override`s in the code, and a good bit of class inheritance. I'd like to flatten things if possible.

Root Widget
===========

Right now things are a bit of a mess, mostly because it's really hard to reason about updates and when effects happen. Using the `Scheduler` is actually a bad idea, I think, and pushing all that stuff to the Platform is a mess.

Instead, I think we should remove almost everything from Platform (and maybe remove platform entirely) and rely on the RootWidget and RootElement to update things instead.

Whenever we request an update from inside an Element, they will call `enqueueForUpdate` on their parent Element. This will continue until we get to the RootElement, which will then schedule a repaint for the next frame. During the render elements will call `enqueueEffect` on their parents in a similar manner, again until we get to the RootClass. Once the render phase is complete, the RootElement will then dispatch all the effects. This should make things simpler.

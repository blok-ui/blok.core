package blok;

/**
  States are similar to Services, and implement a lot of the same
  API (including the `@service(...)` class metadata). The main difference
  is that States are *reactive* -- they can be updated via `@update` methods
  and observed via their `observe(context, build)` static methods.

  This is especially useful if you need to track state in several places,
  or need to handle state for an entire app.

  For simpler situations -- such as toggling between true and false -- consider
  just using a Component's `@update` methods or using `blok.Observable.use(value, ...)`.
**/
@:autoBuild(blok.StateBuilder.build())
interface State extends Disposable {}

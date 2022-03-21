package blok.framework.context;

/**
  Services can be accessed anywhere in the Widget tree via
  the Context api (or via a `@use` property in a Component).

  To make things more predictable, services require a `fallback`
  to be defined in their `@service(...)` metadata, or for
  `@service(isOptional)` to be explicitly set (at which point
  it's up to you to deal with cases where no service is available).

  Use the `blok.framework.context.Provider` to provide an instance of a service to
  all widgets below it in the widget tree.

  > Note: `blok.framework.context.Service` just implements the `blok.framework.context.ServiceProvider`
  > and the `blok.framework.context.ServiceResolver` typedef, along with some 
  > quality-of-life features like `@use` and `@init` metadata.
  > You can create your own service without implementing `blok.framework.context.Service`
  > if you implement those typedefs.

  To use other services in your service, use `@use var service:SomeService`.

  To provide a service, use `@provide var service:SomeService = new SomeService()`.
  This gives you the ability to set up an entire app's dependencies from 
  a single Service, if you desire.

  To run a callback after the Service is registered with `blok.framework.context.Context`
  (and importantly *not* when the class is constructed), use `@init`
  on a method with no arguments (for example, `@init function foo() { ... }`).

  If you want the service to be disposed along with the Context that
  owns it, implement `blok.core.Disposable` as well.
**/
@:autoBuild(blok.framework.context.ServiceBuilder.build())
interface Service {}

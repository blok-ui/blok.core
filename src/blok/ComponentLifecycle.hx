package blok;

import haxe.Exception;

/**
  The various states a component can be in.
**/
enum ComponentLifecycle {
  /**
    Component has not been initialized yet.
  **/
  ComponentPending;

  /**
    Component is initialized, is mounted in the
    component tree and has not been marked as invalid.
  **/
  ComponentValid;

  /**
    Component is initialized, is mounted in the
    component tree but has been marked as invalid
    and will be re-rendered in the next tick.
  **/
  ComponentInvalid;

  /**
    Component encounted an error in the last render and 
    needs to recover.

    Note that a component in this state *cannot* be recovered 
    from -- if it encounters another exception the expection
    will be thrown.
  **/
  ComponentRecovering<T:Exception>(e:T);

  /**
    Component is in the process of rendering.
  **/
  ComponentRendering;

  /**
    Component has been disposed and cannot be used.
  **/
  ComponentDisposed;
}

package blok.context;

import blok.core.Disposable;

@:autoBuild(blok.context.ContextBuilder.build())
interface Context extends Disposable {
  @:noCompletion public function __getContextId():Int;
}

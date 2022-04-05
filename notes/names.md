Names
=====

Right now we have a mess of names: `Components`, `Elements` and `Widgets`, AND when we create a component we do it with a method called `node`.

This is not really easy to parse, so let's step back a bit and think through this.

Basically we have a few layers we're working with:

- The declarative or "virtual" layer -- currently called `Widgets`.
- The "glue" layer, which actually tracks updates and stores the UI -- currently `Elements` (and `Components`, confusingly).
- The render layer, handled by the platform. This one we don't really think about, but we DO call the stuff here `Objects`.

So let's think through this.

First off, perhaps this will work well for our names:

- Declarative layer -> `blok.ui.Node`
- Glue layer -> `blok.ui.Object` and `blok.ui.Component`
- Render layer -> we can refer to these objects as "targets".

This seems like it fits a bit better with our code -- `nodes` create `objects` that are "rendered" to a `target`. Thus, methods like `getObject` should become `getRenderTarget` and so forth. The distinction between `Object` and `Component` is still maybe a bit weird, but I feel this is still better.

Just for testing, here's what the end user would mostly be looking at:

```haxe
package todos;

using Blok;

class TodoContainer extends Component {
  @prop var todo:Todo;

  function render():Node {
    return Html.li({
      className: 'todo-item'
    },
      TodoHeader.node({ title: todo.title }),
      TodoContent.node({ content: todo.content })
    );
  }
}
```

Seems to make a bit more sense?

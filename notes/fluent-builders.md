Fluent Builders
===============

After playing around with it in Pine, I've decided to bring the builder pattern to Blok.

The old way of building nodes will still be available (as it's needed by our XML DSL), but builders are a little more ergonomic:

```haxe
// Old way:
Html.div({ className: 'foo' }, 'Child');
// New way:
Html.div().attr(ClassName, 'foo').child('Child');
```


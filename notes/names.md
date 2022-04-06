Names
=====

Right now we have a mess of names: `Components`, `Elements` and `Widgets`, AND when we create a component we do it with a method called `node`.

This is not really easy to parse, so let's step back a bit and think through this.

Basically we have a few layers we're working with:

- The declarative or "virtual" layer -- currently called `Widgets`.
- The "glue" layer, which actually tracks updates and stores the UI -- currently `Elements` (and `Components`, confusingly).
- The render layer, handled by the platform. This one we don't really think about, but we DO call the stuff here `Objects`.

My attempts to change the naming system keeps running into issues, so I think we're stuck with what we've got here. Widgets, Elements, Components and Objects. The real issue is thus figuring out what to rename the `.node` method on components. This is a big deal -- it's going to be one of the most common things the user is going to type and it needs to make sense. Right now it kind of doesn't.

Some ideas:

```haxe
Foo.of({ prop: 'foo' });
```
I sort of like this one -- it's simple (only two letters!) and mostly makes sense (you're getting a `Foo` made up of `{ prop: 'foo' }`). The one problem is that now `of` and `from` both exist in Blok and mean rather different things, which is potentially odd. That said...

```haxe
Foo.from({ prop: 'foo' });
```
...maybe we just lean into it and use `from` everywhere?

```haxe
Foo.widget({ prop: 'foo' });
```
This is the clearest option. It's only real downside is its length *and* the fact that it conflicts with the existing `widget` property on `Elements`, which we'll have to work around. Not an impossible task though. 

```haxe
Foo.create({ prop: 'foo' });
```
I don't really like this one, mostly because we're not actually creating a `Foo` -- we're creating a `ComponentWidget` that will later instantiate a `Foo` component.

Some other ideas, just for completeness:

```haxe
Foo.into({ prop: 'foo' });
Foo.w({ prop: 'foo' }); // for `[w]idget`
Foo.make({ prop: 'foo' });
Foo.use({ prop: 'foo' }); // ugh
Foo.get({ prop: 'foo' });
Foo.where({ prop: 'foo' });
Foo.with({ prop: 'foo' });
Foo.createWidget({ prop: 'foo' }); // Ugly
```

Right now I'm leaning towards `of`. It's mostly comprehensible, it's really concise, and it sounds pretty good.

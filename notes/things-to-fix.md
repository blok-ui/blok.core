# Things to Fix / Improve

There are a lot of weird things in Blok that could be better, including:

- A less nested directory structure. Most of `blok`, `blok`, `blok`, `blok` and `blok.data` should just be in the `blok` package. This will make importing things a lot simpler.
- Get rid of `Cursor` during hydration. 
- In fact, improve hydration in general. It works but it's really fragile.
- Macros in general make a mess of code completion. Make sure positions are being created correctly.
- Remove most places where we use a callback instead of passing a VNode directly. This doesn't include places where we need to access some context (like inside a scope), but Portal and Root both do this and it doesn't really make any sense.

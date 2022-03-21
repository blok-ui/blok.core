This is an experimental reworking of Blok's backend. The idea is to create something more robust and simple, while not changing the API much.

Note: This approach is a pretty close port (at times basically a direct copy) of Flutter's "framework.dart" file. You can find it [here](https://github.com/flutter/flutter/blob/6af40a7004f886c8b8b87475a40107611bc5bb0a/packages/flutter/lib/src/widgets/framework.dart) (and is why this experiment is called `blok.framework`).

This is only a proof-of-concept, as Flutter's API seems close to how I want Blok to work (and so far it does seem a lot simpler than the current approach found in `blok.ui`). The final implementation will probably differ from this a bit, now that I have a better understanding of what's going on.

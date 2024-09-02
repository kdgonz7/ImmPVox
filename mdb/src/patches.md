# PVox Server Patches

Patches are simply conditional branches of code which do things different from the main source tree. In PVox, these are in the actual `playervox.lua` file, and are simply commands that can alter how PVox works. In the *PVOX > Server Patches* tab, you can find a list of check-boxes, which, when active, will change PVox.

The idea behind patches is that everybody should be able to use PVox how they want to. If there's functionality they want to add, or have, they can either create their own modules with PVox's very easy to use infrastructure, or have the features added by a maintainer. However, these features should **NOT** interfere with PVox's current edition.

Some server patches currently are:

* [Footsteps](./footsteplib.md)
* [Extended Actions](./ea.md)
* [Reload Chances](./relchance.md)
* [Global RNG](./globalrng.md)

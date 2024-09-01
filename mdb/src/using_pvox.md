# Getting Dirty With PVox

While PVox may seem a bit intimidating at first, especially coming from a more player-model based system like **TFA-VOX**, or **Player Expressions**, it is one of the easiest systems to get up and running, as even reported by people using the addon themselves.

To use PVox, simply load into Garry's Mod, open your spawn menu then go to `Options > PVOX > VOX Controls`. Once you have entered that tab, you will be presented with a drop-down to change your PVox preset. You can select any preset you want, by reading their [super secret and secluded code-names](./naming_convention.md), and simply choosing one.

> **Options > PVOX** provides a multitude of features that PVox allows you to change. You have the world at your fingertips!
> All tabs have a purpose, if they don't, that's a problem. Try changing to another and see what you can modify.

Since they update in real time, and PVox is on by default, you are able to use it like normal, reload, commit other actions(not crimes. That is out of the scope of this book), kill enemies, etc.

PVox modules have server and client presence, which means that clients can see modules, however, they are read-only and non-important data. They are mainly used to read modules, not write to them, as a server maintains its own copy of the modules, and the client can only use those modules as information.

E.g. If you want to check if a player has the module 'pie' installed locally, you can do a nil check in conjunction with `GetPlayerModule()`, on the client, it checks if the player has it installed LOCALLY, regardless of if it's a multiplayer game to begin with. However, if it's called on in the server realm, it checks if the **SERVER** can see that module. Client side functions can be called with the local filesystem in hand, therefore can see "ghost modules", or, modules that are installed client-side, and are in the client's files, yet not on the server. For more information on how this works, see [The Shared Module System](./shared_modules.md)

## "Patching" PVox

PVox comes with a patch system, which can be found in the `Options > PVOX > Server Patches` tab. These are essentially branches of modification built-in to PVox without requiring a separate module or file to be instantiated.

These are considered "conditional features", yet they're called patches for simplicity sake.

## Call-out Menu

To create a bind for the call out menu, use the `+pvox_open_callout` command.

> To do that, you can type in the console `bind KEY +pvox_open_callout`, where KEY
> is the key you want to bind to opening call-outs.

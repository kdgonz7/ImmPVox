# The Shared Module System

PVox modules, contrary to popular belief, are shared. Which means that on both the client and server, modules are able to be read from and executed. However, only the server can manage proper modules as well as the actual audio code itself.

Take this client side code as an example:

```lua
for k, v in pairs(PVox.Modules) do
	Combo:AddChoice( k )
end
```

This code is found in `playervox_spawnmenu.lua` and is responsible for adding the client-side modules to the combo box `Combo`. Notice how no net code, or any server-client magic is used? To get all of the existing modules a simple access to the global `PVox.Modules` table has sufficed.

This code works because PVox uses a shared module system, in essence, it creates two copies of the modules as they're being made via the `ImplementModule` function. The client can see its own modules, yet whenever their modules are being called, they're always called from the server.

To the client-side realm, all the mods exist and can work, yet only the server can do real things like modify modules, as well as execute actual action code. If the client's action tables are affected, this means absolutely nothing to the server, and it'll still load like normal.

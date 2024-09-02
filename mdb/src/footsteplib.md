# PVox Footstep Library

> Documentation on this is taken directly from the footstep API documentation, found in *doc/MANUAL.md*

PVox v9 introduces a new footstep API. This new interface allows you to add sounds for specific materials within the Source Engine.

Supported materials are here:

```lua
local PLC_PlayerSoundTable = {
	[0]            = "concrete",
	[MAT_CONCRETE] = "concrete",
	[MAT_TILE] = "concrete",
	[MAT_METAL] = "concrete",
	[MAT_GRASS] = "grass",
	[MAT_SNOW] = "snow",
	[MAT_DEFAULT] = "dirt",
	[MAT_DIRT] = "dirt",
	[MAT_WOOD] = "wood",
	[MAT_GRATE] = "grate",
	[MAT_GLASS] = "glass",
	[MAT_FLESH] = "flesh",
}
```

To create footsteps, you can do it via the classic method, or the procedural way. To make footsteps, you simply must add a `['footsteps']` field to your pack build files.

Every material that you saw there can be used, if you do not want to specify every single material, you are able to make one key, `default`, and put your file paths into it.

```lua
-- in your implementation function...
-- function() return ...
["footsteps"] = {
    ["default"] = {
        "npc/combine_soldier/gear1.wav",
        "npc/combine_soldier/gear2.wav",
        "npc/combine_soldier/gear3.wav",
        "npc/combine_soldier/gear4.wav",
        "npc/combine_soldier/gear5.wav",
        "npc/combine_soldier/gear6.wav",
    }
}
```

Custom footsteps can be enabled/disabled from the PVox **patches** menu.

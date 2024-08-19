# PVox Manual

PVox is a system designed to be efficient and easy to use by providing a low-level interface to audio and mapping action-to-action, as fast and small as possible.

* PVox is *small* (~1K LOC)
* extensive (6 modules built-in + new modules every couple of weeks)
* and user-friendly (all presets are in a spawnmenu category. With an API that supports game modes as well)

# CVars

## pvox_enabled

Should PVox be enabled? Disables all processing if set to `0`.

## pvox_allownotes

Allow PVox to send messages in the chat about it's current state? default is `0`, but can be changed to `1` for debugging.

## pvox_suppresswarnings

Should PVox suppress warnings? (Should be `1` if you don't want a cluttered console)

## pvox_useplayermodelbinds

Should PVox packs be bound to respective player models? `1` for yes, `0` for no.

## pvox_localizedamage

Should damage be called out on a per-limb basis as opposed to a global `take_damage` call map?

## pvox_specifyotherentity

Should entity damage/killing be specified per-entity (only supported entities, see below)--or only by `enemy_killed` + `enemy_spotted`

### Supported Entities

* Combine Soldier
* Antlion
* Zombie
* Zombine (ZOMBIE AND ZOMBINE ARE SEPARATE)
* Stalker
* Manhack

## pvox_senddamageonce

Should kill confirming damage be sent only once? This *rate limits* your body shooting call to once/body.

## pvox_gl_localizationlang

What language should be used for the **global** CC?

## pvox_useclosedcaptioning

Should closed-captioning be used in this server? (ONLY SUPPORTED MODULES)

If a player runs a VOX, it is globally printed to every player in the server.

This is a *new* feature, and is subject to change.

# Footsteps

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

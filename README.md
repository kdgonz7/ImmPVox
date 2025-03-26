# PlayerVox (PVOX)

## Overview

PlayerVox (PVOX) is a Garry's Mod addon designed to give players dynamic voice callouts triggered by various in-game actions, similar to systems found in games like Battlefield. It utilizes a modular system where different "modules" (essentially sound packs) can be created and assigned to players, often based on their player model. The system plays sounds randomly from predefined lists associated with specific actions like reloading, spotting enemies, taking damage, etc.

**Current Version:** `pvox-v11`

## Core Concepts

1.  **Modules:** The central part of PVOX. Each module represents a voice set (e.g., "Combine Soldier", "CS2 SAS"). Modules are defined using `PVox:ImplementModule` and contain tables mapping action names and callout names to lists of sound file paths.
2.  **Actions:** Predefined events that can trigger voice lines (e.g., "reload", "enemy_spotted", "take_damage"). Modules specify which sounds play for which actions.
3.  **Callouts:** Manually triggered voice lines, selectable via a panel or radial menu (as mentioned in changelogs). Modules define available callouts.
4.  **Presets:** A player's selected voice module is stored in the `vox_preset` Networked String (`NWString`). This can be set automatically based on player model (`pvox_useplayermodelbinds`) or manually via UI/commands.
5.  **Sound Emission:** Primarily server-side (`EmitSound`). The system manages cooldowns (`PVOX_Emitting` NWBool) to prevent overlapping sounds, selects random sounds from lists, and handles optional overrides.
6.  **Closed Captioning (CC):** An optional system (`pvox_useclosedcaptioning`) to display text in chat corresponding to the voice lines being played. Requires `ImplementCC` definitions within modules.
7.  **Footsteps:** An optional patch (`pvox_patch_footsteps`) overrides default footstep sounds with module-specific sounds based on the surface material detected under the player.

## File Structure & Loading

* **Core Script:** The main logic resides in the `playervox*.lua` files.
* **Module Files:** External modules are loaded via `PVox:Mount()` from `lua/pvox_module/*.lua`. Each file should use `PVox:ImplementModule` to register its sounds and settings. `AddCSLuaFile` is used to send these module definitions to clients.
* **Sound Files:** The system expects sound files (default `.wav`, customizable per module) to be located in specific subdirectories within `sound/pvox/[module_name]/`, namely:
    * `actions/[action_name]/`: For action-triggered sounds.
    * `callouts/[callout_name]/`: For manual callouts.
    * `footsteps/[surface_name]/`: For custom footstep sounds.

## Technical Details

### Realm

The addon operates in both server and client realms, with careful separation using `if SERVER then` / `if CLIENT then`.
* **Server:** Handles primary logic: event detection (hooks), sound emission (`EmitSound`), state management (NWVars, cooldowns), module loading, ConVar/ConCommand registration, network message handling.
* **Client:** Receives network messages to update UI (callout panel, notifications), receives module definitions via `AddCSLuaFile`. The main script has an early `if CLIENT then return end` preventing most server hooks/functions from running client-side.

### Global Variables

* `PVOX_VersionStr` (String): Stores the current addon version.
* `PVox` (Table): Main addon namespace containing:
    * `Modules` (Table): Stores all loaded module definitions.
    * `PlayerModelBinds` (Table): Maps player model paths to module names.
    * `Blacklisted` (Table): Stores names of modules to prevent loading.
    * `LoadedLUAFiles` (Table): Tracks loaded `pvox_module/*.lua` files.

### Networked Variables (Player NWVars)

* `vox_preset` (String): The name of the currently active module for the player. Default: "none".
* `vox_enabled` (Bool): Player-specific toggle (though `pvox_enabled` seems the primary global toggle). Initialized `true`.
* `PVOX_Emitting` (Bool): Tracks if the player is currently playing a voice line to prevent overlap.
* `PVOX_CachedSound` (String): Stores the path of the currently playing sound (used for stopping/overriding).
* `PVOX_LastSound` (String): Stores the path of the *last* played sound to help prevent immediate repetition.

### Network Messages

Uses `util.AddNetworkString` (Server) and `net.Receive`/`net.Start` (Server/Client).

* **`PVox_ChangePlayerPreset`** (C->S): Client requests the server change their `vox_preset` NWString.
* **`PVox_OpenCalloutPanel`** (S->C): Server sends JSON table of available callouts for the client's current preset, triggering the panel opening.
* **`PVox_PlayAction`** (C->S): Client requests the server play a specific action sound. *Note: This seems unusual; actions are typically triggered server-side via hooks. Ensure this is used securely if client input dictates the action.* (Update: Server receives this, likely triggered by trusted input or other server logic).
* **`PVox_Callout`** (C->S): Client requests the server play a specific manual callout from their preset.
* **`PVox_GetCallouts`** (C->S): Client requests the list of callouts for their preset. (Appears unused in provided code, `PVox_OpenCalloutPanel` seems to handle sending data).
* **`PVox_ReceiveCallouts`** (S->C): Server sends callout data to the client. (Appears unused, see above).

### Console Variables (ConVars)

All are `FCVAR_ARCHIVE` (saved) and `FCVAR_NOTIFY` (notify on change).

* `pvox_enabled` ("1"): Master enable/disable switch.
* `pvox_allownotes` ("0"): Enable `note()` debug messages.
* `pvox_suppresswarnings` ("1"): Disable `warn()` messages.
* `pvox_useplayermodelbinds` ("1"): Automatically set preset based on player model using `PVox.PlayerModelBinds`.
* `pvox_localizedamage` ("0"): Enable hitgroup-specific sounds (e.g., `damage_head`).
* `pvox_specifyotherentity` ("0"): Enable entity class-specific sounds (e.g., `zombie_killed`).
* `pvox_senddamageonce` ("1"): If true, only play kill confirmation sounds (`*_killed`, `confirm_kill`) once per entity death event.
* `pvox_gl_localizationlang` ("en-US"): Language code for Closed Captioning lookups.
* `pvox_gl_volume` ("511"): Global sound volume multiplier (likely clamped 0-255 or similar by `EmitSound` internally). *Note: 511 seems high, typical range is 0-255 or 0-100.*
* `pvox_useclosedcaptioning` ("1"): Enable/disable the CC system.

**Patches/Optional Features ConVars:**

* `pvox_patch_reload` ("1"): Enable the reload action chance mechanic.
* `pvox_patch_reload_chance` ("1"): Chance for reload sound (1 in X). `1` means always play.
* `pvox_patch_footsteps` ("1"): Enable custom footstep sounds.
* `pvox_patch_footsteps_gl_footstepvolume` ("75"): Volume for custom footsteps.
* `pvox_global_rng` ("1"): Global chance modifier for *all* `EmitAction` calls (1 in X). `1` means always attempt to play.
* `pvox_patch_extended_action` ("1"): Enable extra actions like "nice_shot".

### Console Commands (ConCommands)

* `pvox_CalloutPanel` (Client/Server): Sends `PVox_OpenCalloutPanel` net message to the calling client with their module's callout data.
* `pvox_ModuleActions` (Shared): Lists implemented actions for a given module name (uses `note()`).
* `pvox_smart_confirm` (Server): Plays the "confirm_kill" action if the player is looking at a ragdoll (`prop_ragdoll`). Intended for key binding.
* `pvox_ServerModules` (Shared): Lists loaded modules (`PVox.Modules`) and Lua files (`PVox.LoadedLUAFiles`) using `note()`. Requires `pvox_allownotes` to be "1".

### Hooks Used

* `PlayerInitialSpawn`: Sets initial player NWVars.
* `PlayerSpawn`: Sets `vox_preset` based on model (if enabled), plays "on_ready" action. Uses `timer.Simple` for slight delay.
* `PlayerCanPickupWeapon`/`PlayerCanPickupItem`: Plays "pickup_weapon" or "pickup_item" action. Includes basic recursion guards (`_1`, `already_ran_myself`).
* `KeyPress`: Triggers "reload" (with checks/chance), "no_ammo", "frag_out" (grenades), and spotting logic (`enemy_spotted`) via `IN_ATTACK2`. Spotting uses `timer.Simple` and `ents.FindInCone`.
* `OnEntityCreated`: Initializes `Spotted` NWBool on entities.
* `EntityTakeDamage`:
    * Triggers "take_damage" for non-bullet damage on players.
    * Triggers `*_spotted` or `*_killed` when an NPC/NextBot takes bullet damage from a player, handling entity-specific sounds (`pvox_specifyotherentity`) and kill confirmation (`pvox_senddamageonce`).
* `OnNPCKilled`: Triggers "enemy_killed". Also triggers "nice_shot" for nearby friendly players if `pvox_patch_extended_action` is enabled.
* `ScalePlayerDamage`: Triggers "take_damage", "take_damage_in_vehicle", or hitgroup-specific damage sounds (`damage_*`) based on context and `pvox_localizedamage`.
* `PlayerDeath`: Triggers "death" action (with override).
* `PlayerFootstep`: (If `pvox_patch_footsteps` enabled) Determines ground material using `PLC_GetSurfaceMaterial` (internal function) and calls `EmitFootstep` on the player's module. Returns `true` to suppress default sounds if custom sound plays.
* `PVOX_EmitAction` (Custom): Ran before `EmitAction` logic executes, allows blocking (`return false`).
* `PVOX_ModuleBaseClass` (Custom): Ran during `ImplementModule`, allows adding/modifying base methods for all modules.

### Key `PVox` Table Functions

* `PVox:ImplementModule(name, imp_func)`: Registers a module. `imp_func` should return a table defining the module structure (`print_name`, `actions`, `callouts`, etc.). Automatically finds sounds based on folder structure if `imp_func` returns `true`. Merges standard methods (`EmitAction`, `PlayCallout`, etc.) into the module table.
* `PVox:ImplementModuleCallouts(name_string, tab)`: Adds/replaces the `callouts` table for a module.
* `PVox:ImplementCC(lang, mod, audio_str, sent)`: Adds a Closed Caption string for a specific sound file in a module.
* `PVox:Mount()`: Loads all `lua/pvox_module/*.lua` files.
* `PVox:GetPlayerModule(player_obj)`: Returns the module table associated with the player's `vox_preset`.
* `PVox:MinimumRequired(ver, msg, modname)`: Checks if the addon version (`PVOX_VersionStr`) meets a requirement.
* `PVox:RegisterPlayerModel(model, modu)`: Associates a player model file path with a module name for automatic preset selection.
* `PVox:GenerateSimilarNames(amount, common_name, ext, zeroes, prefix)`: Helper to create lists of filenames like `basename_01.wav`, `basename_02.wav`.

### Module Methods (Merged into each module table)

* `EmitAction(ply, action, override, new_time)`: Core function to play an action sound. Handles cooldowns, overriding, random selection, sound duration (`SoundDuration`), preventing repetition (`GetLastSound`), playing the sound (`PlaySoundSafe`), and CC display.
* `EmitActionFallback2(ply, x1, x2, override, _time)`: Plays action `x1`, but falls back to `x2` if `x1` doesn't exist in the module.
* `PlayCallout(ply, callout, override)`: Plays a manual callout sound. Similar logic to `EmitAction`.
* `EmitFootstep(ply, surface_mat)`: Plays a footstep sound based on the surface material.
* `PlaySoundSafe(ply, sound, time)`: Plays a sound (`EmitSound`) and manages the `PVOX_Emitting` state using `timer.Simple`.
* `HasAction(action)`: Checks if the module defines sounds for a given action.
* `IsEmitting(ply)`: Checks the `PVOX_Emitting` NWBool.
* `Get/SetCachedSound(ply, sound)`: Manages the `PVOX_CachedSound` NWString.
* `Get/SetLastSound(ply, sound)`: Manages the `PVOX_LastSound` NWString.
* `GetCalloutCount()` / `GetCallouts()`: Retrieve callout information.

### Built-in Modules

* `combinesoldier`: Half-Life 2 Combine Soldier sounds.
* `cs2-sas`: Counter-Strike 2 SAS sounds.
* `cs2-phoenix`: Counter-Strike 2 Phoenix Connexion sounds.
* `none`: A dummy module with empty action tables, effectively disabling VOX if selected.

## Credits

* PVox takes a part of it's codebase from **PLConv**, a player sound framework that's similar to PVox that was never released.
* PVox is inspired by, yet not very closely related to *TFA-VOX*, a separate VOX mod.

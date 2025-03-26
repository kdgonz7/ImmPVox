# Save System (playervox_saver.lua)

This script adds persistence to the PlayerVox (PVOX) addon, allowing player preset selections (`vox_preset`) to be saved and loaded across server sessions and restarts.

## Overview

The system saves each player's chosen PVOX preset (`vox_preset`) associated with their SteamID64. When a player joins the server, the system attempts to load their previously saved preset and apply it. Data is saved periodically (on player disconnect, server shutdown) or manually via an admin command.

## Technical Details

### Storage Method

* **File:** Player presets are stored in a single JSON file named `pvox_presets.txt` located in the server's `garrysmod/data/` directory.
* **Format:** The file contains a JSON object where keys are player SteamID64s, and values are objects containing player data (currently just the `preset`).
    ```json
    {
      "76561198000000001": {
        "preset": "combinesoldier"
      },
      "76561198000000002": {
        "preset": "cs2-sas"
      }
    }
    ```
* **Caching:** On server initialization (`Initialize` hook), the entire contents of `pvox_presets.txt` are loaded into a server-side Lua table `PVOX_DataStore` for faster runtime access. Player data lookups and updates primarily interact with this in-memory cache.
* **Backup:** If the system fails to read or parse the `pvox_presets.txt` file during initialization (e.g., due to corruption), it will attempt to create a backup copy named `pvox_presets.txt.bak` in the same `data` directory before starting with an empty dataset.

### Key Functions (Server-Side)

* `PVOX_InitializeData()`:
    * Called during the `Initialize` hook.
    * Reads `pvox_presets.txt`.
    * Uses `pcall` and `util.JSONToTable` to safely decode the JSON data.
    * Populates the `PVOX_DataStore` table.
    * Handles file read/decode errors, attempts backup creation, and logs status using `note()`.
* `PVOX_SaveAllDataToFile()`:
    * Called during `PlayerDisconnect`, `ShutDown` hooks, and by the `pvox_saveall` command.
    * Uses `pcall` and `util.TableToJSON` to encode the entire `PVOX_DataStore` table into a JSON string.
    * Writes the JSON string to `pvox_presets.txt`, overwriting the previous content.
    * Handles encoding errors and logs status.
* `PVOX_LoadPlayerData(ply)`:
    * Called (with a small delay) during the `PlayerInitialSpawn` hook.
    * Retrieves the player's SteamID64.
    * Looks up the player's data in the `PVOX_DataStore` cache.
    * If found, sets the player's `vox_preset` Networked String (`NWString`) to the saved value.
    * Sends a notification to the player confirming the loaded preset.
    * Logs status.
* `PVOX_UpdatePlayerData(ply)`:
    * Called when a player's preset is potentially changed (e.g., via `pvox_setpreset`) or just before saving on disconnect.
    * Retrieves the player's SteamID64 and their current `vox_preset` NWString value.
    * Updates the corresponding entry in the `PVOX_DataStore` cache.
    * Logs status.

### Helper Functions

* `file.Copy(source, dest, path)`: Simple utility to read the content of the `source` file and write it to the `dest` file within the specified `path` ID (e.g., "DATA"). Used for creating backups. Returns `true` on success, `false` on failure (e.g., source not found).
* `PVOX_SendNotification(ply, mesg)`: Utility to send a legacy notification message to a specific player using `ply:SendLua`.

### Hooks Used (Server-Side)

* `Initialize`: Triggers `PVOX_InitializeData()` to load all saved data into memory when the server starts.
* `PlayerInitialSpawn`: Triggers `PVOX_LoadPlayerData()` (after a 0.5s delay using `timer.Simple`) to apply the player's saved preset when they join.
* `PlayerDisconnect`: Triggers `PVOX_UpdatePlayerData()` to ensure the latest preset is in the cache, then triggers `PVOX_SaveAllDataToFile()` to write all cached data to the file.
* `ShutDown`: Triggers `PVOX_SaveAllDataToFile()` to ensure data is saved before the server closes.

### Console Commands

* `pvox_saveall` (Server):
    * Requires admin privileges (`ply:IsAdmin()`).
    * Manually triggers `PVOX_SaveAllDataToFile()`.
    * Prints confirmation to the calling admin's chat.
* `pvox_setpreset <preset_name>` (Server):
    * Allows any player to set their PVOX preset.
    * Takes one argument: the name of the desired preset.
    * Sets the player's `vox_preset` NWString.
    * Calls `PVOX_UpdatePlayerData()` to update the in-memory cache immediately.
    * Prints confirmation to the player's chat and sends a notification.
    * *Note:* This command updates the cache but does *not* immediately trigger a save-to-file operation. The data will be written later by the `PlayerDisconnect` or `ShutDown` hooks, or via `pvox_saveall`.

## Workflow Summary

1.  **Server Start:** `Initialize` hook runs `PVOX_InitializeData`,
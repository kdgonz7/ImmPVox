# PVox Generators

PVox has generator functions built-in to ease in the process of creating voice lines and other player expressions.

To access these generator functions, simply call the global `PVox` object.

## `GenerateSimilarNames`

PVox's `GenerateSimilarNames` function does what you think it does. Generates similar names of files.

The signature is as follows: (from `definitions.lua`)

```lua,no_run

--- Generates a table with similar file names. E.g. if you have multiple audio files that are in the format a1.wav, a2.wav, a3.wav, you can
--- use this function to, instead of writing them all out, create a table that automatically generates the names.
---@param amount number      how many names you want to generates
---@param common_name string the common name between all of the files
---@param ext string         the common extension between all the files
---@param zeroes boolean     should zeroes be appended to the filenames < 10? (e.g. a01.wav instead of a1.wav)
---@param prefix string      an (optional) appended prefix for the numbers. e.g. a_01.wav, '_' is the prefix. To disable it, use "" as the prefix for a name like a01.wav
function PVox:GenerateSimilarNames(amount, common_name, ext, zeroes, prefix) end

```

### Usage

To use the function, simply add it into the sound table you would like to define.

From `css_ct.lua`:

```lua,no_run
-- ...
    ["enemy_killed"] = PVox:GenerateSimilarNames(3, "playervox/modules/css/enemy_down", "wav", false, ""),
-- ...
```

This function works because the playervox/modules/css/ directory, looks like this:

```
playervox/modules/css/enemy_down1.wav
playervox/modules/css/enemy_down2.wav
playervox/modules/css/enemy_down3.wav
```

Therefore, the table automatically (and lazily) assumes that these files exist, and create the table with the proper file paths. The extension can also be changed for files that are not `.WAV`.

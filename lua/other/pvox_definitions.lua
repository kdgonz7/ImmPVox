--- @meta

--- The main PVOX table.
--- 
--- It consists of modules, as well as their actiontables.
--- Modules can be unloaded/loaded via this table.
--- 
--- @class PVox_Master
--- @type table
PVox = PVox or {}

--- Initializes a new PVox master record, this holds modules
--- and probably shouldn't be used unless you know what you're doing.
function PVox:New() end

--- Returns the amount of actions in module `modu`.
--- 
--- This requires the module to be in the global PVox.Modules table.
--- 
---@param modu string
---@return number
function PVox:GetTotalSoundCount(modu) end

--- adds `modu' to the PVox master blacklist.
--- @param modu string
--- @return nil
function PVox:BlackListModule(modu) end

--- returns true if the module 'modu' is in the global blacklist.
--- @nodiscard
--- @param modu string
--- @return boolean
function PVox:ModuleIsBlackListed(modu) end

--- Registers the playermodel `model` to `modu`. This means that if player model binding is enabled,
--- whenever the player loads in, if they have 'model' selected, modu will be executed.q
--- @param model string
--- @param modu string
--- @return nil
function PVox:RegisterPlayerModel(model, modu) end

--- Saves the PM binds to file.
--- 
--- 🛠️ this function was implemented in v7. So any outdated versions should be updated.
--- 
--- @return nil
function PVox:SaveModelTable() end

--- Saves the blacklist to file.
--- 
--- 🛠️ *again, this function was implemented in v7.*
--- 
--- 🛠️ *So any outdated versions should be updated for this to work*
--- 
--- @return nil
function PVox:SaveBlackList() end

--- Loads all of the players presets from file.
--- 
--- **NOTE**: this function should not be called manually. It has a speed of O(N) and will slow down PVOX.
--- @return nil
function PVOX_LoadPresets() end

--- Verifies every parameter passed in and returns `true` if all of them are NOT nil.
--- 
--- ```lua
--- if PVOX_Verify(1, 2, 3, nil) then
---     print("this will never run")
--- else
---     print("the only viable option")
--- end
--- ```
--- @param ... unknown
function PVOX_Verify(...) end

--- Implements `name` using `imp_func`, which should return a table, or a boolean and an extension string.
--- 
--- @see PVOX_ModuleBaseClass
---@param name string
---@param imp_func function
function PVox:ImplementModule(name, imp_func) end

--- Adds the audio_str to the Closed Captions for module `mod`, in language `lang`. `sent` will be printed
--- while the audio is playing.
--- @param lang string
--- @param mod string
--- @param audio_str string
--- @param sent string
function PVox:ImplementCC(lang, mod, audio_str, sent) end

--- Sets `name_string`'s callouts table to `tab`.
--- @param name_string string
--- @param tab table
function PVox:ImplementModuleCallouts(name_string, tab) end

--- Returns the player's module. Gets the `player_obj`'s networked string, `vox_preset`.
--- @param player_obj Player
--- @nodiscard
--- @return PVOX_ModuleBaseClass
function PVox:GetPlayerModule(player_obj) end

--- Enables the CC with in module `name`. CC is a v8 feature, therefore might need an update before it can be used.
--- @param name string
function PVox:EnableCC(name) end

--- Generates a table with similar file names. E.g. if you have multiple audio files that are in the format a1.wav, a2.wav, a3.wav, you can
--- use this function to, instead of writing them all out, create a table that automatically generates the names.
---@param amount number      how many names you want to generates
---@param common_name string the common name between all of the files
---@param ext string         the common extension between all the files
---@param zeroes boolean     should zeroes be appended to the filenames < 10? (e.g. a01.wav instead of a1.wav)
---@param prefix string      an (optional) appended prefix for the numbers. e.g. a_01.wav, '_' is the prefix. To disable it, use "" as the prefix for a name like a01.wav
function PVox:GenerateSimilarNames(amount, common_name, ext, zeroes, prefix) end

--- Errors if ver is not met. `ver` is a string that is in the format of `pvox-v[...]`, where `[...]` is the version number. e.g. pvox-v3.
--- It then parses this input and checks it against the currently installed version. While, this isn't the best way to do it,
--- It is a way to ensure that a module is compatible with a certain version, especially in the earlier versions of PVOX, where there was
--- a lot of things being added at one time, and some things breaking APIs.
--- @param ver string       The version string
--- @param msg string       The error message
--- @param modname string   The name of the module
function PVox:MinimumRequired(ver, msg, modname) end

--- Cleans all blank modules from the actiontable registry. This function was originally used when modules had created extra, empty
--- tables on the side via `ImplementModule`.
--- 
--- **Since** 1.0
function PVox:CleanBlankModules() end

--- @class PVOX_ModuleBaseClass
--- ## Module Base Class
--- It's used by `PVox:ImplementModule` to implement and use a module. PVox uses a registry that tags modules via name, similar to TFA-VOX, however
--- when creating a module, this class isn't accessed directly, as instances of this class are returned by `PVox:ImplementModule`
--- 
--- ```lua
--- PVox:ImplementModule("my_handle" /* or 'mdlprefix' */, {
---     return {
---         ['actions'] = {
---             ['pickup_weapon'] = {}
---             /* .... */
---         }
---     }
--- })
--- ```
--- 
--- @see PVox.ImplementModule 
PVOX_ModuleBaseClass = PVOX_ModuleBaseClass or {}

--- Emits an action. Similar to @`ply:EmitSound`, it will emit the sound from the player's module's soundtable.
--- 
--- When ran, if `override` is not true, then it will check if we have a sound currently playing. If there is,
--- then we will wait until it is finished. If `override` is true, then it will always emit the sound, regardless
--- of if we have one playing or not, which takes away PVOX's throttling method.
--- 
--- `new_time` is similar to TFA-VOX's `delay` parameter, in essence, it gives a time to wait after emitting a sound.
--- This is useful if you want to make sure that you don't spam the same sound, and you don't already have `SoundDuration()`
--- support for your specific format.
--- 
--- For `.ogg` files, since they do not support SoundDuration, they will be played for `0.2` seconds by default. And it is
--- recommended to add a bit more time to new_time depending on the length of your sound.
---  
--- @see PVox.ImplementModule
--- @see SoundDuration
--- @see Player.EmitSound
--- 
--- @param ply Player
--- @param action string
--- @param override? boolean
--- @param new_time? number
function PVOX_ModuleBaseClass:EmitAction(ply, action, override, new_time) end

--- Unticks `ply.Emitting`.
--- @param self table
--- @param ply Player
--- @see PVOX_ModuleBaseClass.StartEmit
--- @return nil
PVOX_ModuleBaseClass.StopEmit = function(self, ply) end

--- Ticks `ply.Emitting`. This is a variable used as a throttle to prevent spamming of similar sounds.
--- @param self table
--- @param ply Player
--- @see PVOX_ModuleBaseClass.StopEmit
--- @return nil
PVOX_ModuleBaseClass.StartEmit = function(self, ply) end

--- Emits a footstep on `surface_mat` implemented by the player's current module 
--- @param self PVOX_ModuleBaseClass
--- @param ply Player
--- @param surface_mat string
PVOX_ModuleBaseClass.EmitFootstep = function(self, ply, surface_mat) end

--- Sets `ply.CachedSound`.
--- @param self table
--- @param ply Player
--- @param f string
--- @return nil
PVOX_ModuleBaseClass.SetCachedSound = function(self, ply, f) end

--- A getter for `ply.CachedSound`. Used primarily for non-overriden EmitActions.
--- @param self table
--- @param ply Player
--- @see PVOX_ModuleBaseClass.SetCachedSound
--- @return string
PVOX_ModuleBaseClass.GetCachedSound = function(self, ply) end

--- Checks if `action` exists in `PVox.Modules[self]["actions"]`.
--- @param self table
--- @param ply Player
--- @param action string
--- @see PVox.ImplementModule
--- @return boolean
PVOX_ModuleBaseClass.HasAction = function(self, ply, action) end

--- Checks if `ply.Emitting` is true.
--- @param self table
--- @param ply Player
PVOX_ModuleBaseClass.IsEmitting = function(self, ply) end

--- A wrapper around `ply:EmitSound` that contains a throttling method as well as a sound duration check.
--- 
--- This should be used in place of `ply:EmitSound`, when possible.
--- 
--- There are no calculations made on `time`, these checks should be made by the caller. This function
--- can simply determine how long a sound should be running for and play it for that respective time.
--- 
--- @param self table
--- @param ply Player
--- @param sound string
--- @param time number
PVOX_ModuleBaseClass.PlaySoundSafe = function(self, ply, sound, time) end

--- Plays a callout from the current modules `callouts` table.
--- @param self table
--- @param ply Player
--- @param callout string
PVOX_ModuleBaseClass.PlayCallout = function(self, ply, callout) end

--- ## PVOX Verification
--- 
--- To verify multiple objects, with `nil` checks, you can use
--- this function.
--- 
--- @param ... any        items to be checked
function PVOX_Verify(...) end

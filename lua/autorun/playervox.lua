PVOX_VersionStr = "pvox-v9-git-71da691"

-- # PlayerVox (PVOX)
--
-- Give players a voice!
--
--
-- gives players a voice, similar to games like battlefield,
-- where the player can hear other players character callouts

-- the vox system will work by using a simple file management system
-- e.g. player_reload_01
--
-- files will have numbers at the end, and it will allow them to be called at random,
-- depending on how many files there are.
--
-- custom modules can be implemented and mapped to player actions. for example,
-- there can be a module that implements reloads like so:
--
-- PVox:ImplementModule("player_name", function(ply) <implement hooks> end)
--
-- As a bonus, there (hopefully) will be a menu to choose custom callouts, that are
-- handled by the module. For example, a module can implement a callout called "Can't Find Them"
-- and it will show up in the menu. Once played, it will play the VOX audio for that callout.
--
-- Built-in modules:
--	* "reload"                    called on reload
--	* "enemy_spotted"             called when aiming at an enemy
--	* "enemy_killed"              called when an enemy is killed
--	* "take_damage"               called when a player takes damage ( 1 in 5 chance )
--	* "no_ammo"                   called when a player runs out of ammo
--	* "confirm_kill"              called when an enemy is confirmed to be killed (shot at dead body)
--	* "death"                     called when a player dies (not required)
--	* "on_ready"                  called when a player spawns
--	* "pickup_weapon"             called when a player picks up a weapon. This takes priority over on_ready, so add your on_ready files into this instead.
--	* "inspect"                   called when the key `F` is pressed.
--	* "take_damage_in_vehicle"    called when the player takes damage in a vehicle.
--	* "[ENTITY]_spotted"          called when a specific entity is spotted. requires PVoxSpecifyEntity to be on
--	* "[ENTITY]_killed"           called when a specific entity dies. requires PVoxSpecifyEntity to be on
--	* "damage_[HITGROUP]"         called when a specific part of a player is shot. requires PVoxLocalizeDamage to be on
--
-- Unnecessary/Potentially Deprecated Modules:
--
--	* "switchtaunt"				called when a player switches their weapon.
--
-- 100% inspired by TFA-VOX, thanks for the playermodel-based preset ideas.
--
-- Modules - the modules that PVox currently has
--	actions - the actions with their respective functions.
--
-- 'actions' is a key-value table in the PVox.Modules table. 
-- It contains the pairs of actions, binded to their sound tables.
-- depending on how many sounds you add, you can randomize the chances of certain sounds.
--
-- New in version v0.0.4 - there will potentially be a API upgrade, allowing
-- developers to easily create sound packs by specifying an AutoCreate(),
-- where it will essentially create the module code for you,
-- and all you have to do is store the sounds in a certain order.

if SERVER then
	util.AddNetworkString("PVox_ChangePlayerPreset")
	util.AddNetworkString("PVox_OpenCalloutPanel")
	util.AddNetworkString("PVox_Callout") -- Callout(ply, calloutname)
end

PVox = PVox or {
	Modules = {},
	PlayerModelBinds = {},
	Blacklisted = {},
	LoadedLUAFiles = {},
}

local PVoxEnabled                = CreateConVar("pvox_enabled", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxAllowNotes             = CreateConVar("pvox_allownotes", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxSuppressWarnings       = CreateConVar("pvox_suppresswarnings", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxUsePlayerModelBinds    = CreateConVar("pvox_useplayermodelbinds", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxLocalizeDamage         = CreateConVar("pvox_localizedamage", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxSpecifyEntity          = CreateConVar("pvox_specifyotherentity", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxSendDamageOnce         = CreateConVar("pvox_senddamageonce", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxGlobalLocalizationLang = CreateConVar("pvox_gl_localizationlang", "en_US", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxGlobalVolume           = CreateConVar("pvox_gl_volume", "511", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxUseCC                  = CreateConVar("pvox_useclosedcaptioning", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY})

--[[
	Patches
		(AKA) "Modules", but integrated within the addon itself. These are 100% optional and come with their own
		set of options. PVox will never add anything behind the user's back. All calls are 100% FLOSS
]]

local PVoxEnableReloadChancePatch = CreateConVar("pvox_patch_reload", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxReloadChance            = CreateConVar("pvox_patch_reload_chance", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY})

local PVoxEnableFootstepsPatch    = CreateConVar("pvox_patch_footsteps", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxGlobalFootstepVolume    = CreateConVar("pvox_patch_footsteps_gl_footstepvolume", "75", {FCVAR_ARCHIVE, FCVAR_NOTIFY})

local PVoxGlobalRNGPatch          = CreateConVar("pvox_global_rng", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY})

local PVoxExtendedActions         = CreateConVar("pvox_patch_extended_action", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY})

function warn(msg)
	if PVoxSuppressWarnings:GetBool() then return end
	MsgC(Color(255, 119, 0), "[PVox]", Color(255, 255, 255), " " .. msg .. "\n")
end

---@diagnostic disable-next-line: lowercase-global
function note(msg)
	if ! PVoxAllowNotes:GetBool() then return end

	MsgC(Color(0, 229, 255), "[PVox]", Color(255, 255, 255), " " .. msg .. "\n")
end

function PVox:New()
	return self
end

function PVox:GetTotalSoundCount(modu)
	local mod = PVox.Modules[modu]

	if ! mod then return 0 end
	if ! mod.actions then return 0 end

	local final = 0

	for k, v in pairs(mod.actions) do
		final = final + #v
	end

	return final
end

function PVOX_Verify(...)
	local arg_count = select('#', ...)

	for i = 1, arg_count do
		local arg = select(i, ...)
		if ! IsValid(arg) or arg == nil then
			return false
		end
	end

	return true
end

function PVox:MinimumRequired(ver, msg, modname)
	-- will error if the PVox_VersionStr does not match ver.
	-- ver should be in the format "v<whatever version number>, and if the version does not match it will error."
	-- e.g usage
	-- 
	-- PVox:MinimumRequired("pvox-v3")
	
	if ! PVOX_VersionStr then
		error ("PVox:MinimumRequired was called before PVox was initialized!")
	end

	local vers = string.Replace(ver, "pvox-v", "")
	local our_vers = string.sub(PVOX_VersionStr, 7, -13) -- don't count the pvox-v or the decimal

	local vers_n = tonumber(vers)
	local our_vers_n = tonumber(our_vers)

	if ! vers_n or ! our_vers_n then
		error ("PVox:MinimumRequired was called with an invalid version number!")
	end

	if our_vers_n < vers_n then
		error (msg or ("PVox is not updated. Please reinstall from the steam workshop to use " .. modname))
	end
end

function PVox:BlackListModule(modu)
	PVox.Blacklisted[modu] = true
end

function PVox:ModuleIsBlackListed(modu)
	return PVox.Blacklisted[modu] or false
end

function PVox:RegisterPlayerModel(model, modu)
	if ! modu or ! model then return end

	PVox.PlayerModelBinds[model] = modu
	note("bound " .. model .. " to " .. modu)
end

function PVox:SaveModelTable()
	-- saves the model table to a file, this
	-- function is called EVERY TIME a new player model bind is set.
	-- this function CAN and SHOULD be called in VOX packs.
end

function PVox:SaveBlackList()
	-- saves the black list.
end

--- Sets the callout table to `tab` in module `name_string`.
function PVox:ImplementModuleCallouts(name_string, tab)
	if ! PVox.Modules[name_string] then return end

	PVox.Modules[name_string].callouts = tab
end

function PVox:Mount()
	note("Mounting PVox simple modules!")

	local c = 0
	for _, f in pairs(file.Find("pvox_module/*.lua", "LUA")) do
		include("pvox_module/" .. f)
		AddCSLuaFile("pvox_module/" .. f)

		PVox.LoadedLUAFiles[f] = true

		c = c + 1
	end

	note("finished loading, found " .. c .. " modules.")
end

--- Returns the player's current module based on their internal `vox_preset`.
---@param player_obj Player  the actual player
---@return PVOX_ModuleBaseClass|nil mod the module
function PVox:GetPlayerModule(player_obj)
	local ppr = player_obj:GetNWString("vox_preset", "none")
	local m = PVox.Modules[ppr]
	if m then return m else return nil end
end

--- Enables closed-captioning. A system designed to make your life and communication easier.
---@param name string
function PVox:EnableCC(name)
	if ! name then return end
	if ! PVox.Modules[name] then return end

	PVox.Modules[name].CCEnabled = true
end

function PVox:ImplementCC(lang, mod, audio_str, sent)
	if ! PVox.Modules[mod] then return end
	if ! PVox.Modules[mod].cc then return end
	if ! PVox.Modules[mod].cc[lang] then
		PVox.Modules[mod].cc[lang] = {}
	end

	PVox.Modules[mod].cc[lang][audio_str] = sent

	note("[CCv9] added " .. audio_str .. " to " .. lang .. " for " .. mod)
end

--* NOTE if you're using glualint,
--* this entire section is a bunch of warnings. ignore them.
--* this is for the PVOX class.
function PVox:ImplementModule(name, imp_func)
	if PVox:ModuleIsBlackListed(name) then
		warn("could not implement module " .. name .. " because it is blacklisted.")
		return
	end

	local ext
	PVox.Modules[name], ext = imp_func()

	ext = ext or "wav"

	note("loaded module " .. name)
	note(tostring(PVox.Modules[name]))

	if PVox.Modules[name] == true and name then	-- new in 0.4 - we create the module on the fly
		PVox.Modules[name] = {}

		PVox.Modules[name]["actions"]   = {}
		PVox.Modules[name]["callouts"]  = {}
		PVox.Modules[name]["cc"]        = {}
		PVox.Modules[name]["footsteps"] = {}

		PVox.Modules[name].CCEnabled    = false

		local module_folder = "pvox/" .. name -- sound/pvox/MODNAME will be used

		note("creating module for " .. name)

		local _,dirs = file.Find("sound/" .. module_folder .. "/actions/*", "GAME")
		local _,fdirs = file.Find("sound/" .. module_folder .. "/footsteps/*", "GAME")
		local _,cdirs = file.Find("sound/" .. module_folder .. "/callouts/*", "GAME")

		if ! dirs then
			warn("structure incorrect. failed to create module")
		end

		for _, v in pairs(dirs) do
			note("found module pack " .. v)

			PVox.Modules[name]["actions"][v] = {}

			local afiles, _ = file.Find("sound/" .. module_folder .. "/actions/" .. v .. "/*." .. ext, "GAME")

			for _, v2 in pairs(afiles) do
				PVox.Modules[name]["actions"][v][#PVox.Modules[name]["actions"][v] + 1] = module_folder .. "/actions/" .. v .. "/" .. v2
			end
		end

		-- literally reusing code lmfao
		for _, v in pairs(fdirs) do
			note("found footstep pack " .. v)

			PVox.Modules[name]["footsteps"][v] = {}

			local afiles, _ = file.Find("sound/" .. module_folder .. "/footsteps/" .. v .. "/*." .. ext, "GAME")

			for _, v2 in pairs(afiles) do
				-- found a footstep sound, we add it to the list
				PVox.Modules[name]["footsteps"][v][#PVox.Modules[name]["footsteps"][v] + 1] = module_folder .. "/footsteps/" .. v .. "/" .. v2
			end
		end

		-- for callouts
		for _, v in pairs(cdirs) do
			note("found callout pack " .. v)

			PVox.Modules[name]["callouts"][v] = {}

			local afiles, _ = file.Find("sound/" .. module_folder .. "/callouts/" .. v .. "/*." .. ext, "GAME")

			for _, v2 in pairs(afiles) do
				-- found a footstep sound, we add it to the list
				PVox.Modules[name]["callouts"][v][#PVox.Modules[name]["callouts"][v] + 1] = module_folder .. "/callouts/" .. v .. "/" .. v2
			end
		end
	end

	if ! name then
		warn("no name for module, skipping")
		return
	end

	local m_name = PVox.Modules[name]["print_name"]

	m_name = m_name or name

	note("loaded module " .. m_name)
	note("total soundtable count: " .. self:GetTotalSoundCount(name))
	note("actual name: " .. name)

	table.Merge(PVox.Modules[name], {
		StopEmit = function(self, ply)
			ply:SetNWBool("PVOX_Emitting", false)
		end,

		StartEmit = function(self, ply)
			ply:SetNWBool("PVOX_Emitting", true)
		end,

		IsEmitting = function(self, ply)
			return  ply:GetNWBool("PVOX_Emitting", false)
		end,

		SetCachedSound = function(self, ply, f)
			ply:SetNWString("PVOX_CachedSound", f)
		end,

		GetCachedSound = function(self, ply)
			return ply:GetNWString("PVOX_CachedSound", "")
		end,

		SetLastSound = function(self, ply, sound)
			ply:SetNWString("PVOX_LastSound", sound)
		end,

		GetLastSound = function(self, ply)
			return ply:GetNWString("PVOX_LastSound", "")
		end,

		HasAction = function(self, action)
			if ! PVox.Modules[name] or ! PVox.Modules[name]["actions"] then return false end
			return PVox.Modules[name]["actions"][action] ~= nil
		end,

		EmitAction = function(self, ply, action, override, new_time)
			if ! IsValid(ply) then return end

			if CLIENT then return end

			if PVoxGlobalRNGPatch:GetInt() > 1 then
				if math.random(0, PVoxGlobalRNGPatch:GetInt()) != 1 then
					return
				end
			end

			local r = hook.Run("PVOX_EmitAction", ply, action, override, new_time)

			if r == false then
				return
			end

			override = override or false
			new_time = new_time or 0

			if ! override and self:IsEmitting(ply) then
				return
			else
				if (self:GetCachedSound(ply) ~= nil) then
					note(self:GetCachedSound(ply))

					ply:StopSound(self:GetCachedSound(ply))

					note("clearing old sound, overriden")
					self:SetCachedSound(ply, "")
					self:StopEmit(ply)
				end
			end

			if ! PVox.Modules[name].actions then return end

			local action_soundtable = PVox.Modules[name]["actions"][action]

			if type(action_soundtable) == "string" then
				action_soundtable = PVox.Modules[name]["actions"][action_soundtable]
			end

			if ! action_soundtable then
				warn("could not find action soundtable '" .. action .. "'. going to ignore the request.")
				return
			end

			if #action_soundtable == 0 then return end

			local rand_sound = action_soundtable[math.random(1, #action_soundtable)]
			local dur = SoundDuration(rand_sound)

			-- FIXME: disable if performance tanks hard
			-- FIXME: should tank at worse O(n), n being the length of action sound_table but that's worse worse
			if rand_sound == self:GetLastSound(ply) and #action_soundtable > 1 then
				while rand_sound == self:GetLastSound(ply) do
					rand_sound = action_soundtable[math.random(1, #action_soundtable)]
				end
			end

			if dur == 60 then
				dur = 0.5
			end

			self:SetCachedSound(ply, rand_sound)
			self:SetLastSound(ply, rand_sound)
			self:PlaySoundSafe(ply, rand_sound, dur + new_time)

			if (PVox.Modules[name].CCEnabled) then
				-- sends to chat the CC of the audio string

				if ! PVox.Modules[name].cc then return end
				if ! PVox.Modules[name].cc[PVoxGlobalLocalizationLang:GetString()] then return end

				local ccstr = PVox.Modules[name].cc[PVoxGlobalLocalizationLang:GetString()][rand_sound]

				if ! ccstr then return end
				if ! PVoxUseCC:GetBool() then return end

				PrintMessage(HUD_PRINTTALK, ply:Nick() .. ": " .. ccstr)
			end
		end,

		-- Like EmitAction, but plays `x2` if `x1` does not exist.
		-- e.g. EmitActionFallback2(ply, "zombie_killed", "enemy_killed")
		EmitActionFallback2 = function(self, ply, x1, x2, override, _time)
			return (! PVOX_Verify(ply, x1, x2, override, _time)) or (function()
				local m = PVox:GetPlayerModule(ply)

				-- verify m exists
				if PVOX_Verify(m) then
					if m == nil then return end
					-- verify x1 exists
					if ! m:HasAction(ply, x1) then
						-- if x1 does not exist, emit x2
						m:EmitAction(ply, x2, override, _time)
					else
						-- if x1 exists, just emit x1
						m:EmitAction(ply, x1, override, _time)
					end
				else
					return
				end
			end)()
		end,

		EmitFootstep = function(self, ply, surface_mat)
			if ! IsValid(ply) then return end
			if CLIENT then return end

			-- since this is supposed to be ran from playerfootstep hook
			-- we don't need as many bounds checks

			if (! PVox.Modules[name]) or (PVox.Modules[name]["footsteps"] == nil) then return end

			local us = PVox.Modules[name]["footsteps"][surface_mat]

			if ! us then
				us = PVox.Modules[name]["footsteps"]["default"] or nil
			end

			if istable(us) and us != nil then
				local rand_sound = us[math.random(1, #us)]

				ply:EmitSound(rand_sound, PVoxGlobalFootstepVolume:GetInt())

				return true
			end

			return false
		end,

		---@param ply Player
		PlaySoundSafe = function(self, ply, sound, time)
			if CLIENT then return end
			if self:IsEmitting(ply) then return end

			time = time or 0

			ply:SetNWBool("PVOX_Emitting", true)

			ply:EmitSound(sound, PVoxGlobalVolume:GetInt())

			timer.Simple(time, function()
				if ! IsValid(ply) then return end

				ply:SetNWBool("PVOX_Emitting", false)
			end)
		end,

		PlayCallout = function(self, ply, callout, override)
			if ! IsValid(ply) then return end
			if ! override and self:IsEmitting(ply) then
				return
			else
				if (self:GetCachedSound(ply) ~= nil) then
					note(self:GetCachedSound(ply))

					ply:StopSound(self:GetCachedSound(ply))

					note("clearing old sound, overriden")
					self:SetCachedSound(ply, "")
					self:StopEmit(ply)
				end
			end

			local sound = PVox.Modules[name]["callouts"][callout]

			if ! sound then
				warn("could not find callout '" .. callout .. "'. going to ignore the request.")
				return
			end

			if type(sound) == "table" then
				sound = sound[math.random(1, #sound)]
			end

			local dur = SoundDuration(sound)

			if dur == 60 then
				dur = 0.5
			end

			self:SetCachedSound(ply, sound)
			self:PlaySoundSafe(ply, sound, dur)

			if (PVox.Modules[name].CCEnabled) then
				-- sends to chat the CC of the audio string

				if ! PVox.Modules[name].cc then return end
				if ! PVox.Modules[name].cc[PVoxGlobalLocalizationLang:GetString()] then return end

				local ccstr = PVox.Modules[name].cc[PVoxGlobalLocalizationLang:GetString()][sound]

				if ! ccstr then return end
				if ! PVoxUseCC:GetBool() then return end

				PrintMessage(HUD_PRINTTALK, ply:Nick() .. ": " .. ccstr)
			end
		end,

		GetCalloutCount = function(self)
			return table.Count(PVox.Modules[name]["callouts"])
		end,

		GetCallouts = function(self)
			return PVox.Modules[name]["callouts"]
		end,

	}, false)

	local addTo = hook.Run("PVOX_ModuleBaseClass", name) or {}

	table.Merge(PVox.Modules[name], addTo)
end

function PVox:Version()
	return PVOX_VersionStr
end

function PVox:GetModule(name)
	return PVox.Modules[name]
end

function PVox:CleanBlankModules()
	for k, v in pairs(PVox.Modules) do
		if table.Count(v) == 0 then
			PVox.Modules[k] = nil
		end
	end
end

function PVOX_LoadPresets()
	local tb = file.Read("pvox_presets.txt")
	if ! tb then return end

	local JS = util.JSONToTable(tb)
	if ! JS then return end

	local allPlayers = player.GetAll()

	for k,v in pairs(JS) do
		local ply = player.GetBySteamID64(k)
		if ! IsValid(ply) then continue end
		if ! ply then continue end

		ply:SetNWString("vox_preset", v)
	end
end

function PVOX_LoadPreset(player)
	PVOX_LoadPresets() --todo: might make this better
end

-- this is a fake member function lol
-- it's not a part of the PVOX class, but
-- still has the name PVOX in it
function PVOX_SavePreset()
	--iterate through every player
	-- save their preset to a table

	local tbl_presets = {}

	for _, v in pairs(player.GetAll()) do
		tbl_presets[v:SteamID64()] = v:GetNWString("vox_preset", "none")
	end

	local JS = util.TableToJSON(tbl_presets) -- convert to JSON

	note("saved PVox Presets!")
	file.Write("pvox_presets.txt", JS)
end

function PVox:GenerateSimilarNames(amount, common_name, ext, zeroes, prefix)
	zeroes = zeroes or false
	prefix = prefix or "_"

	local st = {}

	for i = 1, amount do
		if zeroes and i < 10 then
---@diagnostic disable-next-line: cast-local-type
			i = "0" .. i
		end

		local str = common_name .. prefix .. i .. "." .. ext
		table.insert(st, str)
	end

	return st
end

if SERVER then
	net.Receive("PVox_ChangePlayerPreset", function(len, ply)
		local new_preset = net.ReadString()
		if ! new_preset then return end

		ply:SetNWString("vox_preset", new_preset)
	end)

	net.Receive("PVox_GetCallouts", function(len, ply)
		if ! IsValid(ply) then return end

		local player_Module = PVox:GetModule(ply:GetNWString("vox_preset", "none"))
		if ! player_Module then return end

		local callouts = player_Module["callouts"]
		if ! callouts then return end

		net.Start("PVox_ReceiveCallouts")
		net.WriteString(util.TableToJSON(callouts))
		net.Send(ply)
	end)

	net.Receive("PVox_Callout", function(len, ply)
		local callout = net.ReadString()
		local preset = ply:GetNWString("vox_preset", "none")
		local player_Module = PVox:GetModule(preset)

		if ! player_Module then return end
		player_Module:PlayCallout(ply, callout, true)
	end)
end

local mdl_loading_start = CurTime()

--* note: this mounts PVox modules (includes each file)
--* this process isn't that complicated
PVox:Mount()

--* these are the default modules.
--* by default comes with Combine Soldier, CS2 SAS, and CS2 Phoenix Connexion voice lines.
--*
--* using this same formula, it's very easy to implement new voice modules, as long
--* as you have paths to the sound files. :)
--*
--* You can also use strings to alias certain action tables.
--* e.g. i want the enemy spotted to be the same as killed i'd do
--*			["enemy_killed"] = "enemy_spotted"
PVox:ImplementModule("combinesoldier", function(ply)
	return {
		["actions"] = {
			["print_name"] = "Half-Life 2 Combine Soldier VOX",
			["description"] = "A module that contains Half-Life 2 Combine voice lines.",
			["tags"] = {
				"player",
				"communication",
				"team",
				"voice"
			},
			["reload"] = {
				"playervox/modules/combinesoldier/player_reload_01.wav",
				"playervox/modules/combinesoldier/player_reload_02.wav",
			},

			["enemy_spotted"] = {
				"playervox/modules/combinesoldier/player_enemy_spotted_01.wav",
				"playervox/modules/combinesoldier/player_enemy_spotted_02.wav",
				"playervox/modules/combinesoldier/player_enemy_spotted_03.wav",
			},

			["enemy_killed"] = {
				"playervox/modules/combinesoldier/player_enemy_elim_01.wav",
				"playervox/modules/combinesoldier/player_enemy_elim_02.wav",
				"playervox/modules/combinesoldier/player_enemy_elim_03.wav",
				"playervox/modules/combinesoldier/player_enemy_elim_04.wav",
				"playervox/modules/combinesoldier/player_enemy_elim_05.wav",
				"playervox/modules/combinesoldier/player_enemy_elim_06.wav",
			},

			["take_damage"] = {
				"playervox/modules/combinesoldier/player_take_damage_01.wav",
				"playervox/modules/combinesoldier/player_take_damage_02.wav",
				"playervox/modules/combinesoldier/player_take_damage_03.wav",
				"playervox/modules/combinesoldier/player_take_damage_04.wav",
			},

			["no_ammo"] = {
				"playervox/modules/combinesoldier/player_no_ammo_01.wav",
				"playervox/modules/combinesoldier/player_no_ammo_02.wav",
			},

			["confirm_kill"] = {
				"playervox/modules/combinesoldier/player_confirm_kill_01.wav",
				"playervox/modules/combinesoldier/player_confirm_kill_02.wav",
			},

			["death"] = {
				"playervox/modules/combinesoldier/player_death_01.wav",
				"playervox/modules/combinesoldier/player_death_02.wav",
				"playervox/modules/combinesoldier/player_death_03.wav",
			},

			["frag_out"] = {
				"npc/combine_soldier/vo/dagger.wav",
			}
		},

		-- 
		["callouts"] = {
			["Report"] = {
				"npc/combine_soldier/vo/overwatchreportspossiblehostiles.wav",
				"npc/combine_soldier/vo/sectorisnotsecure.wav",
			},

			["Target Lost"] = {
				"npc/combine_soldier/vo/phantom.wav",
				"npc/combine_soldier/vo/prepforcontact.wav",
				"npc/combine_soldier/vo/movein.wav",
			}
		},

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
	}
end)

PVox:ImplementModule("cs2-sas", function(ply)
	return {
		["print_name"] = "CS2 SAS Operator (Ported)",
		["description"] = "A port (most of) the CS2 SAS Operator voice lines.",
		["actions"] = {
			["reload"] = {
				"playervox/modules/sas/coverme01.wav",
				"playervox/modules/sas/coverme02.wav",
				"playervox/modules/sas/coverme03.wav",
			},

			["enemy_spotted"] = {
				"playervox/modules/sas/coverme01.wav",
				"playervox/modules/sas/radio.enemyspotted01.wav",
				"playervox/modules/sas/radio.enemyspotted02.wav",
				"playervox/modules/sas/radio.enemyspotted03.wav",
				"playervox/modules/sas/radio.enemyspotted04.wav",
				"playervox/modules/sas/radio.enemyspotted05.wav",
				"playervox/modules/sas/radio.enemyspotted06.wav",
				"playervox/modules/sas/radio.enemyspotted07.wav",
				"playervox/modules/sas/radio.enemyspotted08.wav",
			},

			["enemy_killed"] = {
				"playervox/modules/sas/enemydown01.wav",
				"playervox/modules/sas/enemydown02.wav",
				"playervox/modules/sas/enemydown03.wav",
				"playervox/modules/sas/enemydown04.wav",
				"playervox/modules/sas/enemydown05.wav",
				"playervox/modules/sas/enemydown06.wav",
			},

			["other_killed"] = {
				--* this is a new feature
				--* allows for any type of NPC to be here, for CUSTOM audio
				--* 
				--* no preset types yet
			},

			["take_damage"] = {
				"playervox/modules/sas/radio.takingfire01.wav",
				"playervox/modules/sas/radio.takingfire02.wav",
				"playervox/modules/sas/radio.takingfire03.wav",
				"playervox/modules/sas/radio.takingfire04.wav",
				"playervox/modules/sas/radio.takingfire05.wav",
			},

			["no_ammo"] = {},

			["frag_out"] = {
				"playervox/modules/sas/ct_grenade01.wav",
				"playervox/modules/sas/ct_grenade02.wav",
				"playervox/modules/sas/ct_grenade03.wav",
				"playervox/modules/sas/ct_grenade04.wav",
			},

			["on_ready"] = {
				"playervox/modules/sas/radio.letsgo01.wav",
				"playervox/modules/sas/radio.letsgo02.wav",
				"playervox/modules/sas/radio.letsgo03.wav",
				"playervox/modules/sas/radio.letsgo05.wav",
				"playervox/modules/sas/radio.letsgo06.wav",
				"playervox/modules/sas/radio.letsgo07.wav",
			},

			["death"] = {
				"playervox/modules/sas/ct_death01.wav",
				"playervox/modules/sas/ct_death02.wav",
				"playervox/modules/sas/ct_death03.wav",
				"playervox/modules/sas/ct_death04.wav",
				"playervox/modules/sas/ct_death05.wav",
				"playervox/modules/sas/ct_death06.wav",
			},

			["confirm_kill"] = {
				"playervox/modules/sas/enemydown07.wav",
				"playervox/modules/sas/enemydown08.wav",
				"playervox/modules/sas/enemydown09.wav",
				"playervox/modules/sas/enemydown10.wav",
				"playervox/modules/sas/enemydown11.wav",
				"playervox/modules/sas/enemydown12.wav",
				"playervox/modules/sas/enemydown13.wav",
				"playervox/modules/sas/enemydown14.wav",
				"playervox/modules/sas/enemydown15.wav",
			},
		}
	}
end)

-- Built-in modules:
--       * "reload"               called on reload
--       * "enemy_spotted"        called when aiming at an enemy
--       * "enemy_killed"         called when an enemy is killed
--       * "take_damage"          called when a player takes damage ( 1 in 5 chance )
--       * "no_ammo"              called when a player runs out of ammo
--       * "confirm_kill"         called when an enemy is confirmed to be killed (shot at dead body)
--       * "death"                called when a player dies (not required)
--       * "on_ready"             called when a player spawns
PVox:ImplementModule("cs2-phoenix", function(ply)
	return {
		["print_name"] = "CS2 Phoenix Connexion VOX (Ported)",
		["description"] = "A port of (most) Counter-Strike 2 Terrorist voice lines.",
		["callouts"] = {
			["Need Backup"] = {
				"playervox/modules/phoenix/taunt/radio_needbackup01.wav",
				"playervox/modules/phoenix/taunt/radio_needbackup02.wav",
				"playervox/modules/phoenix/taunt/radio_needbackup03.wav",
				"playervox/modules/phoenix/taunt/radio_needbackup05.wav",
				"playervox/modules/phoenix/taunt/radio_needbackup06.wav",
			},
		},
		["actions"] = {
			["on_ready"] = {
				"playervox/modules/phoenix/radio_letsgo05.wav",
			},
			["enemy_spotted"] = {
				"playervox/modules/phoenix/incombat01.wav",
				"playervox/modules/phoenix/incombat02.wav",
				"playervox/modules/phoenix/incombat03.wav",
				"playervox/modules/phoenix/incombat04.wav",
				"playervox/modules/phoenix/incombat05.wav",
				"playervox/modules/phoenix/incombat06.wav",
				"playervox/modules/phoenix/incombat07.wav",
				"playervox/modules/phoenix/incombat08.wav",
				"playervox/modules/phoenix/incombat09.wav",
			},

			["enemy_killed"] = {
				"playervox/modules/phoenix/enemydown01.wav",
				"playervox/modules/phoenix/enemydown02.wav",
				"playervox/modules/phoenix/enemydown03.wav",
				"playervox/modules/phoenix/enemydown04.wav",
				"playervox/modules/phoenix/enemydown05.wav",
				"playervox/modules/phoenix/enemydown06.wav",
				"playervox/modules/phoenix/enemydown07.wav",
				"playervox/modules/phoenix/enemydown08.wav",
				"playervox/modules/phoenix/enemydown09.wav",
			},

			["take_damage"] = {
				"playervox/modules/phoenix/radio_takingfire01.wav",
				"playervox/modules/phoenix/radio_takingfire02.wav",
				"playervox/modules/phoenix/radio_takingfire03.wav",
				"playervox/modules/phoenix/radio_takingfire04.wav",
				"playervox/modules/phoenix/radio_takingfire05.wav",
				"playervox/modules/phoenix/radio_takingfire06.wav",
			},

			["take_damage_in_vehicle"] = {
				"playervox/modules/phoenix/radio_takingfire01.wav",
				"playervox/modules/phoenix/radio_takingfire02.wav",
				"playervox/modules/phoenix/radio_takingfire03.wav",
			},

			["no_ammo"] = {},

			["death"] = {
				"playervox/modules/phoenix/t_death01.wav",
				"playervox/modules/phoenix/t_death02.wav",
				"playervox/modules/phoenix/t_death03.wav",
				"playervox/modules/phoenix/t_death04.wav",
				"playervox/modules/phoenix/t_death05.wav",
			},

			["confirm_kill"] = {
				"playervox/modules/phoenix/clear01.wav",
				"playervox/modules/phoenix/clear02.wav",
				"playervox/modules/phoenix/clear03.wav",
				"playervox/modules/phoenix/clearedarea01.wav",
				"playervox/modules/phoenix/clearedarea02.wav",
				"playervox/modules/phoenix/clearedarea03.wav",
			},

			["reload"] = {
				"playervox/modules/phoenix/coverme01.wav",
				"playervox/modules/phoenix/coverme02.wav",
				"playervox/modules/phoenix/coverme03.wav",
			},

			["switchtaunt"] = {
				"playervox/modules/phoenix/onarollbrag10.wav",
				"playervox/modules/phoenix/onarollbrag11.wav",
				"playervox/modules/phoenix/onarollbrag12.wav",
				"playervox/modules/phoenix/onarollbrag13.wav",
				"playervox/modules/phoenix/onarollbrag14.wav",
				"playervox/modules/phoenix/onarollbrag15.wav",
				"playervox/modules/phoenix/radio_letsgo05.wav",

			},

			["frag_out"] = {
				"playervox/modules/phoenix/t_grenade02.wav",
				"playervox/modules/phoenix/t_grenade04.wav",
				"playervox/modules/phoenix/t_grenade05.wav",
			},

			["inspect"] = "switchtaunt",
			["pickup_weapon"] = "switchtaunt",
		}
	}
end)

--* for developers: this is probably not going to get called
PVox:ImplementModule("none", function(ply)
	return {
		["print_name"] = "None (A dummy module)",
		["actions"] = {
			["on_ready"] = {},
			["enemy_spotted"] = {},
			["enemy_killed"] = {},
			["take_damage"] = {},
			["no_ammo"] = {},
			["death"] = {},
			["frag_out"] = {},
			["confirm_kill"] = {},
			["reload"] = {},
			["switchtaunt"] = {},
		},
	}
end)

local mdl_loading_end = CurTime()
local mdl_loading_total = mdl_loading_end - mdl_loading_start

warn("module loading took " .. mdl_loading_total .. "s :-)")

concommand.Add("pvox_CalloutPanel", function(ply, cmd, args)
	local preset = ply:GetNWString("vox_preset", "none")

	if preset ~= "none" then
		local mod = PVox:GetModule(preset)

		if ! mod.callouts then return end

		if mod then
			net.Start("PVox_OpenCalloutPanel")
			net.WriteString(util.TableToJSON(mod.callouts))
			net.Send(ply)
		end
	end
end)

concommand.Add("pvox_ModuleActions", function(ply, cmd, args)
	local module = args[1]

	if ! module then return end
	if ! PVox.Modules[module].actions then return end
	if ! PVox.Modules[module] then return end

	for aname, atable in pairs(PVox.Modules[module].actions) do
		note("module " .. module .. " implements action " .. aname)
	end
end)

-- we use a simple kill confirm bind instead of automatic detection.
-- this just feels better when playing
concommand.Add("pvox_smart_confirm", function(ply, args, cmd)
	local et = ply:GetEyeTrace()
	local ent = et.Entity

	if ! IsValid(ent) then return end
	if (ent:GetClass() ~= "prop_ragdoll") then return end

	local pr = ply:GetNWString("vox_preset", "none")
	if pr == "none" then return end

	local mod = PVox.Modules[pr]
	ply:SetNWBool("RanFromSmart", true)
	mod:EmitAction(ply, "confirm_kill")
	ply:SetNWBool("RanFromSmart", false)
end)

concommand.Add("pvox_ServerModules", function(ply, cmd, args)
	if ! PVoxAllowNotes:GetBool() then
		print("hi! if you're seeing this then it means you have pvox_allownotes set to 0. which means the server modules won't print")
		return
	end

	note("listing server VOX modules")

	for k, v in pairs(PVox.Modules) do
		v.description = v.description or ""
		v.print_name = v.print_name or ""
		note(k)
		note("\tName: " .. (v.print_name or ""))
		note("\tDescription: " .. (v.description or ""))
	end

	note("listing server LUA modules")

	for k, v in pairs(PVox.LoadedLUAFiles) do
		note("	loaded LUA module '" .. k .. "'") -- todo: add descriptions (k)
	end
end)

if SERVER then
	MsgC(Color(255, 0, 230), "[PVOX SERVER]", Color(255, 255, 255), " PlayerVox loaded v0.0.1\n")
end

if CLIENT then return end
hook.Add("PlayerInitialSpawn", "StartPlayerValues", function(ply)
	ply:SetNWString("vox_preset", "none")
	ply:SetNWBool("vox_enabled", true)
	ply:SetNWBool("PVOX_Emitting", false)
	ply:SetNWString("PVOX_CachedSound", "")

	-- loaded network stuff, we're good.

	-- PVOX_LoadPresets()
end)

hook.Add("PlayerSpawn", "StartPlayerPresetByModel", function(ply)
	if ! PVoxEnabled:GetBool() then return end
	if ! PVoxUsePlayerModelBinds:GetBool() then return end

	timer.Simple(0.1, function()
		if ply:GetNWString("vox_preset", "none") ~= "none" then return end
		local model = ply:GetModel()
		local pm_preset = PVox.PlayerModelBinds[model]

		if pm_preset ~= "none" and pm_preset ~= nil then
			ply:SendLua("notification.AddLegacy('your preset has been set to " .. pm_preset .. "', NOTIFY_GENERIC, 6)")
			ply:SetNWString("vox_preset", pm_preset)
		else
			ply:SendLua("notification.AddLegacy('No registered presets found for this model.', NOTIFY_GENERIC, 6)")
			timer.Simple(1, function()
				if ! IsValid(ply) then return end
				ply:SendLua("notification.AddLegacy('If you want to use this PM, you might have to configure it.', NOTIFY_HINT, 6)")
			end)
			ply:SetNWString("vox_preset", "none")
		end

			-- call on_ready VOX from the player's preset
			local player_preset = ply:GetNWString("vox_preset", "none")
			local mod = PVox:GetModule(player_preset)

			timer.Simple(0.1, function()
				if mod then
					mod:EmitAction(ply, "on_ready")
				end
			end)
	end)
end)

hook.Add("PlayerCanPickupWeapon", "PlayerVoxPickupSound", function(ply, wep)
	if _1 then return end

	_1 = true
	local res = hook.Run("PlayerCanPickupWeapon", ply, wep)

	if res == false then _1 = false; return false end
	_1 = false

	local preset = ply:GetNWString("vox_preset", "none")

	if preset ~= "none" then
		local mod = PVox:GetModule(preset)

		if mod then
			mod:EmitAction(ply, "pickup_weapon")
		end
	end

	return true
end)

hook.Add("PlayerCanPickupItem", "PlayerVoxPickupSound", function(ply, wep)
	if _1 then return end

	_1 = true
	local res = hook.Run("PlayerCanPickupItem", ply, wep)

	if res == false then _1 = false; return false end
	_1 = false

	local preset = ply:GetNWString("vox_preset", "none")

	if preset ~= "none" then
		local mod = PVox:GetModule(preset)

		if mod then
			if mod:HasAction(ply, "pickup_item") then
				mod:EmitAction(ply, "pickup_item")
			else
				mod:EmitAction(ply, "pickup_weapon")
			end
		end
	end

	return true
end)

-- hook.Add("WeaponEquip", "W", function(wep, own)
-- 	wep.RanOG = false
-- 	wep.Reload = function (self)
-- 		if ! self.RanOG then
-- 			self.RanOG = true
-- 			self:Reload()
-- 		end

-- 		print("ran reload")

-- 		-- if we already have enough,
-- 		-- stop spamming

-- 		if ! IsValid(wep) then
-- 			warn("tried to call built-in module reload with no active weapon. non-fatal.")
-- 			return
-- 		end

-- 		if wep:Clip1() >= wep:GetMaxClip1() then return end

-- 		-- play the reload VOX from the player's preset
-- 		local playerPreset = own:GetNWString("vox_preset", "none")

-- 		if playerPreset ~= "none" then
-- 			local mod = PVox:GetModule(playerPreset)

-- 			if mod then
-- 				if own:GetAmmoCount(wep:GetPrimaryAmmoType()) == 0 then mod:EmitAction(ply, "no_ammo") return end
-- 				mod:EmitAction(ply, "reload")
-- 			end
-- 		end
-- 	end
-- end)

hook.Add("KeyPress", "PlayerVoxDefaults", function(ply, key)
	if ! PVoxEnabled:GetBool() then return end

	if key == IN_RELOAD then
		-- if we already have enough,
		-- stop spamming
		local wep = ply:GetActiveWeapon()

		if ! IsValid(wep) then
			warn("tried to call built-in module reload with no active weapon. non-fatal.")
			return end

		if wep:Clip1() >= wep:GetMaxClip1() then return end

		-- play the reload VOX from the player's preset
		local playerPreset = ply:GetNWString("vox_preset", "none")

		if playerPreset ~= "none" then
			local mod = PVox:GetModule(playerPreset)

			if mod then
				if ply:GetAmmoCount(wep:GetPrimaryAmmoType()) == 0 then mod:EmitAction(ply, "no_ammo") return end

				-- PVox Reload Chance Patch
				if PVoxEnableReloadChancePatch:GetBool() then
					--- @type any
					local cond = math.random(1, PVoxReloadChance:GetInt())

					-- add a note for comparison
					note(cond .. " == 1")

					-- reset it
					cond = cond == 1

					-- if true then reload
					if cond then
						mod:EmitAction(ply, "reload")
					end

					-- otherwise, discard
				else
					mod:EmitAction(ply, "reload")
				end
			end
		end
	end

	
end)

-- most hitgroups supported.
-- at least the major ones
--
-- can't believe this wasnt implemented by default lol
local HGT = {
	[HITGROUP_HEAD] = "head",
	[HITGROUP_CHEST] = "chest",
	[HITGROUP_STOMACH] = "stomach",
	[HITGROUP_LEFTARM] = "leftarm",
	[HITGROUP_LEFTLEG] = "leftleg",
	[HITGROUP_RIGHTARM] = "rightarm",
	[HITGROUP_RIGHTLEG] = "rightleg",
	[HITGROUP_GENERIC] = "generic",
	[HITGROUP_GEAR] = "gear",
}

-- some NPC support
local NPCS = {
	["npc_combine_s"]         = "soldier",
	["npc_metropolice"]       = "soldier",
	["npc_manhack"]           = "manhack",
	["npc_stalker"]           = "stalker",
	["npc_antlion"]           = "antlion",
	["npc_antlionguard"]      = "antlion",
	["npc_barnacle"]          = "barnacle",
	["npc_fastzombie"]        = "zombie",
	["npc_fastzombietorso"]   = "zombie",
	["npc_poisonzombie"]      = "zombie",
	["npc_zombie"]            = "zombie",
	["npc_zombine"]           = "zombine",
}

hook.Add("OnEntityCreated", "SmartManage", function(ent)
	if ! IsValid(ent) then return end
	ent:SetNWBool("Spotted", false)
end)

-- we instead run spotted on entities TAKING DAMAGE
-- this sounds way better in practice and makes for a
-- much less immersion breaking game.
--- @param ent Entity
--- @param dm CTakeDamageInfo
hook.Add("EntityTakeDamage", "SmartDamageAlerts", function (ent, dm)
	---@class Player
	local pot_ply = dm:GetAttacker()
	if ! pot_ply:IsPlayer() then return end

	if ent == pot_ply then return end

	local mod = PVox:GetPlayerModule(pot_ply)

	if ! mod then return end
	if ! dm:IsDamageType(DMG_BULLET) then return end
	if ! ent:IsNextBot() and ! ent:IsNPC() and ! ent:IsRagdoll() then return end

	local spcc = "enemy"
	local e_class = ent:GetClass()

	if PVoxSpecifyEntity:GetBool() then
		local npcclass = NPCS[e_class] or false

---@diagnostic disable-next-line: need-check-nil
		if (! npcclass) then
			spcc = "enemy"
			warn("no enemy implemented for " .. ent:GetClass() .. ". defaulting to `enemy_*'")
		else
			spcc = NPCS[e_class]
		end
	end


	if ent:Health() > 0 and ent:GetNWBool("Spotted", false) == false then
		ent:SetNWBool("Spotted", true)
		if ! mod:HasAction(pot_ply, spcc .. "_spotted") then
			mod:EmitAction(pot_ply, "enemy" .. "_spotted")
			return
		end

		mod:EmitAction(pot_ply, spcc .. "_spotted")
	elseif ent:Health() <= 0 then
		if ent:GetNWBool("Spotted", false) == true or ! PVoxSendDamageOnce:GetBool() then
			if ! mod:HasAction(pot_ply, spcc .. "_killed") then
				mod:EmitAction(pot_ply, "enemy" .. "_killed")
				return
			end

			mod:EmitAction(pot_ply, spcc .. "_killed", PVoxSendDamageOnce:GetBool())
			ent:SetNWBool("Spotted", false)
		end
	end
end)

hook.Add("OnNPCKilled", "PlayerVoxOnNPCKilled", function(npc, attacker, inflictor)
	if ! IsValid(npc) then return end
	if ! IsValid(attacker) then return end

	local playerPreset = attacker:GetNWString("vox_preset", "none")

	if playerPreset ~= "none" then
		local mod = PVox:GetModule(playerPreset)

		if mod then
			mod:EmitAction(attacker, "enemy_killed")
		end
	end
end)

--- @param npc NPC
--- @param attacker Player
--- @param inflictor Entity
hook.Add("OnNPCKilled", "PlayerVoxNicePatch", function (npc, attacker, inflictor)
	if ! IsValid(npc) then return end
	if ! IsValid(attacker) then return end
	if ! PVoxExtendedActions:GetBool() then return end
	if ! attacker:IsNPC() then return end

	local ents_in_rad = ents.FindInSphere(attacker:GetPos() + Vector(0, 0, 32), 300)

	--- @param ent Entity
	for _, ent in pairs(ents_in_rad) do
		if ! ent:IsPlayer() then continue end
		if ! attacker.Disposition then continue end
		
		if attacker:Disposition(ent) != D_HT && ent:Visible(npc) then
			-- if we don't hate them, then tell them nice shot
			pmod:EmitAction(ent, "nice_shot")
		end
	end
end)

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

-- ripped from unused addon PLC, for player sound tables.
-- adds a quick trace to get the surface material under player.
local function PLC_GetSurfaceMaterial(ply)
	if ! IsValid(ply) then return end

	local ppos = ply:GetPos()
	local ft = util.QuickTrace(ppos + Vector(0,0,35), ppos - Vector(0, 0, 20), ply)

	return PLC_PlayerSoundTable[ft.MatType or 0] -- 0: concrete
end

-- adds player footsteps
hook.Add("PlayerFootstep", "PlayerVoxOnFootstep", function (ply, pos, foot, sound, volume, filter)
	if PVoxEnableFootstepsPatch:GetBool() == false then return false end

	local plyMod = PVox:GetPlayerModule(ply)

	if plyMod then
		local surf = PLC_GetSurfaceMaterial(ply)
		if ! plyMod:EmitFootstep(ply, surf) then return false else return true end
	end
end)

--- 
--- @param ent Entity
--- @param dm CTakeDamageInfo
hook.Add("EntityTakeDamage", "PlayerVoxOnDamage", function (ent, dm)
	local is_general_damage = ! (dm:IsDamageType(DMG_BULLET))
	if ! is_general_damage then return end

	if ! IsValid(ent) or ! ent:IsPlayer() then return end


	local m = PVox:GetPlayerModule(ent)
	if ! m then return end

	-- general damage action here
	m:EmitAction(ent, "take_damage")
end)

hook.Add("ScalePlayerDamage", "PlayerVoxPlayerShouldTakeDamage", function(ply, hitgroup, dmginfo)
	if ! IsValid(ply) then return end

	local mod = PVox:GetPlayerModule(ply)
	if ! mod then return end

	local chance = math.random(1, 1) == 1

	if ! ply:InVehicle() and chance then
		if PVoxLocalizeDamage:GetBool() then
			local hgts = HGT [ hitgroup ]
			if ! hgts then return warn("there was no key to supply " .. hitgroup .. ". please report this to developers. pvox_localizedamage") end

			local js = "damage_" .. hgts

			if ! mod:HasAction(ply, js) then
				warn("couldn't find a localized damage module. might not support it :/")
				warn("play `take_damage' instead")
				mod:EmitAction(ply, "take_damage")
			else
				mod:EmitAction(ply, js)
			end
		else
			mod:EmitAction(ply, "take_damage")
		end
	else
		if ! chance then return end
		mod:EmitAction(ply, "take_damage_in_vehicle")
	end
end)

hook.Add("ShutDown", "PlayerVoxSavePreset", PVOX_SavePreset)

hook.Add("PlayerDeath", "PlayerVoxPlayerDeath", function(ply, inflictor, attacker)
	if ! IsValid(ply) then return end
	if ! IsValid(attacker) then return end

	local plyMod = PVox:GetModule(ply:GetNWString("vox_preset", "none"))
	if ! plyMod then return end

	plyMod:EmitAction(ply, "death", true)
end)

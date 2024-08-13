local PVOX_VersionStr = "pvox-v6.5-git-8102a86"

--[[ GMod Utility Scripts ]]
-- PlayerVox
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

local PVoxEnabled                = CreateConVar("pvox_enabled", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxAllowNotes             = CreateConVar("pvox_allownotes", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxSuppressWarnings       = CreateConVar("pvox_suppresswarnings", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxUsePlayerModelBinds    = CreateConVar("pvox_useplayermodelbinds", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxLocalizeDamage         = CreateConVar("pvox_localizedamage", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
local PVoxSpecifyEntity          = CreateConVar("pvox_specifyotherentity", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY})

concommand.Add("pvox_ServerModules", function(ply, cmd, args)
	if ! PVoxAllowNotes then
		print("hi! if you're seeing this then it means you have pvox_allownotes set to 0. which means the server modules won't print")
		return
	end

	note("listing server VOX modules")

	for k, v in pairs(PVox.Modules) do
		v.description = v.description or ""
		v.print_name = v.print_name or ""
		note(k)
		note("\tName: " .. v.print_name or "")
		note("\tDescription: " .. v.description or "")
	end

	note("listing server LUA modules")

	for k, v in pairs(PVox.LoadedLUAFiles) do
		note("	loaded LUA module '" .. k .. "'") -- todo: add descriptions (k)
	end
end)

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

	local final = 0

	for k, v in pairs(mod.actions) do
		final = final + #v
	end

	return final
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

function PVox:GetPlayerModule(player_ob)
	local ppr = player_ob:GetNWString("vox_preset", "none")
	local m = PVox.Modules[ppr]
	if m then return m else return nil end
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
		PVox.Modules[name]["actions"] = {}

		local module_folder = "pvox/" .. name -- sound/pvox/MODNAME will be used

		note("creating module for " .. name)
		local _,dirs = file.Find("sound/" .. module_folder .. "/actions/*", "GAME")

		if ! dirs then
			warn("structure incorrect. failed to create module")
		end

		for k, v in pairs(dirs) do
			note("found module pack " .. v)

			PVox.Modules[name]["actions"][v] = {}

			local afiles, _ = file.Find("sound/" .. module_folder .. "/actions/" .. v .. "/*." .. ext, "GAME")

			for _, v2 in pairs(afiles) do
				PVox.Modules[name]["actions"][v][#PVox.Modules[name]["actions"][v] + 1] = module_folder .. "/actions/" .. v .. "/" .. v2
			end
		end
		--* this is uncommented on Steam Workshop version
		-- PrintTable(PVox.Modules[name])
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

		HasAction = function(self, action)
			if ! PVox.Modules[name] or ! PVox.Modules[name]["actions"] then return false end
			return PVox.Modules[name]["actions"][action] ~= nil
		end,

		EmitAction = function(self, ply, action, override, new_time)
			if ! IsValid(ply) then return end
			if CLIENT then return end
			local r = hook.Run("PVOX_EmitAction", ply, action, override, new_time) or true
			
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

			if dur == 60 then
				dur = 0.5
			end

			timer.Simple(0, function()
				self:SetCachedSound(ply, rand_sound)
				self:PlaySoundSafe(ply, rand_sound, dur + new_time)
			end)
		end,

		PlaySoundSafe = function(self, ply, sound, time)
			if CLIENT then return end
			if self:IsEmitting(ply) then return end

			time = time or 0

			ply:SetNWBool("PVOX_Emitting", true)

			ply:EmitSound(sound, 511)

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

			self:PlaySoundSafe(ply, sound, 0)
		end
	}, false)

	local addTo = hook.Run("PVOX_ModuleBaseClass", name) or {}

	table.Merge(PVox.Modules[name], addTo)
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

			["frag_out"] = {
				"playervox/modules/combinesoldier/player_frag_out_01.wav",
			},

			["confirm_kill"] = {
				"playervox/modules/combinesoldier/player_confirm_kill_01.wav",
				"playervox/modules/combinesoldier/player_confirm_kill_02.wav",
			},

			["death"] = {
				"playervox/modules/combinesoldier/player_death_01.wav",
				"playervox/modules/combinesoldier/player_death_02.wav",
				"playervox/modules/combinesoldier/player_death_03.wav",
			}
		},

		-- 
		["radial_Callouts"] = {
			["Taunt"] = {
				""
			}
		},
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
			["Need Help!"] = {
				"playervox/modules/phoenix/taunt/radio_needbackup01.wav",
				"playervox/modules/phoenix/taunt/radio_needbackup02.wav",
				"playervox/modules/phoenix/taunt/radio_needbackup03.wav",
				"playervox/modules/phoenix/taunt/radio_needbackup05.wav",
				"playervox/modules/phoenix/taunt/radio_needbackup06.wav",
			},

			["Need Help 2"] = {
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

if SERVER then
	MsgC(Color(255, 0, 230), "[PVOX SERVER]", Color(255, 255, 255), " PlayerVox loaded v0.0.1\n")
end

if CLIENT then return end
hook.Add("PlayerInitialSpawn", "StartPlayerValues", function(ply)
	ply:SetNWString("vox_preset", "combinesoldier")
	ply:SetNWBool("vox_enabled", true)
	ply:SetNWBool("PVOX_Emitting", false)
	ply:SetNWString("PVOX_CachedSound", "")

	-- loaded network stuff, we're good.

	PVOX_LoadPresets()
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
	local preset = ply:GetNWString("vox_preset", "none")

	if preset ~= "none" then
		local mod = PVox:GetModule(preset)

		if mod then
			mod:EmitAction(ply, "pickup_weapon")
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
				mod:EmitAction(ply, "reload")
			end
		end
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
hook.Add("EntityTakeDamage", "SmartDamageAlerts", function (ent, dm)
	local pot_ply = dm:GetAttacker()
	if ! pot_ply:IsPlayer() then return end

	local mod = PVox:GetPlayerModule(pot_ply)

	if ! ent:IsNextBot() and ! ent:IsNPC() and ! ent:IsRagdoll() then return end

	local spcc = "enemy"
	local e_class = ent:GetClass()

	if PVoxSpecifyEntity:GetBool() then
		if (! NPCS[e_class] or ! mod:HasAction(NPCS[e_class])) then
			spcc = "enemy"
			warn("no enemy implemented for " .. ent:GetClass() .. ". defaulting to `enemy_*'")
		else
			spcc = NPCS[e_class]
		end
	end

	if ent:Health() > 0 and ent:GetNWBool("Spotted", false) == false then
		ent:SetNWBool("Spotted", true)
		mod:EmitAction(pot_ply, spcc .. "_spotted")
	elseif ent:Health() <= 0 then
		mod:EmitAction(pot_ply, spcc .. "_killed")
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

hook.Add("ScalePlayerDamage", "PlayerVoxPlayerShouldTakeDamage", function(ply, hitgroup, dmginfo)
	if ! IsValid(ply) then return end

	local mod = PVox:GetPlayerModule(ply)
	if ! mod then return end

	local chance = math.random(1, 5) == 1

	if ! ply:InVehicle() and chance then
		if PVoxLocalizeDamage:GetBool() then
			local hgts = HGT [ hitgroup ]
			if ! hgts then return warn("there was no key to supply " .. hitgroup .. ". please report this to developers. pvox_localizedamage") end

			local js = "damage_" .. hgts

			if ! mod:HasAction(js) then
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

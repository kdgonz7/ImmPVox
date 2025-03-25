--! This is a converted module from TFA-VOX to PVox for nZombies integration

local MODULE = {}

MODULE.name = "nZombies - Perks, Box, Facilities etc."
MODULE.description = "Plays sounds based on nZombies events"
MODULE.authors = {["Zet0r"] = "TFA-VOX Module for NZombies", ["kdgonz7"] = "Converting it to PVox"}
MODULE.realm = "shared"

-- Helper function to check if player has valid PVox module
local function IsPlayerValid(ply)
	return IsValid(ply) and PVox:GetPlayerModule(ply) != nil
end

-- Helper function to get random valid player with PVox
local function GetRandomValidPlayer(exclude)
	local plys = player.GetAllPlayingAndAlive()
	local valid = {}
	
	for _, ply in pairs(plys) do
		if IsPlayerValid(ply) and ply:GetNotDowned() and ply != exclude then
			table.insert(valid, ply)
		end
	end
	
	return table.Random(valid)
end

-- Perks
hook.Add("OnPlayerGetPerk", "PVox_nZombies_Perks", function(ply, id, machine)
	timer.Simple(1, function()
		if IsPlayerValid(ply) and ply:HasPerk(id) then
			local plm = PVox:GetPlayerModule(ply)
			-- Use generic perk voice line occasionally or if specific one isn't available
			if math.random(0, 3) == 0 or !plm:HasAction("nzombies.perk." .. tostring(id)) then
				id = "generic"
			end
			
			timer.Simple(0, function()
				if IsValid(ply) and ply:HasPerk(id) then
					plm:EmitAction("nzombies.perk." .. tostring(id))
				end
			end)
		end
	end)
end)

-- Round preparation
hook.Add("OnRoundPreparation", "PVox_nZombies_Round", function(round)
	if round and round > 1 then
		timer.Simple(3, function()
			if nzRound:InProgress() then
				local ply = GetRandomValidPlayer()
				
				if IsValid(ply) then
					local plm = PVox:GetPlayerModule(ply)
					plm:EmitAction("nzombies.round.prepare")
					
					-- Play reply 3 seconds later
					timer.Simple(3, function()
						if nzRound:InProgress() then
							local ply2 = GetRandomValidPlayer(ply)
							
							if IsValid(ply2) then
								local plm2 = PVox:GetPlayerModule(ply2)
								plm2:EmitAction("nzombies.round.preparereply")
							end
						end
					end)
				end
			end
		end)
	end
end)

-- Round start
hook.Add("OnRoundStart", "PVox_nZombies_Round", function(num)
	if nzRound:IsSpecial() then
		local ply = GetRandomValidPlayer()
		
		if IsValid(ply) then
			local plm = PVox:GetPlayerModule(ply)
			plm:EmitAction("nzombies.round.special")
		end
	end
end)

-- Powerups
hook.Add("OnPlayerPickupPowerUp", "PVox_nZombies_Powerups", function(ply, id, ent)
	timer.Simple(2.5, function()
		if nzRound:InProgress() and IsPlayerValid(ply) then
			local plm = PVox:GetPlayerModule(ply)
			
			-- Use generic powerup voice line occasionally or if specific one isn't available
			if math.random(0, 3) == 0 or !plm:HasAction("nzombies.powerup." .. id) then
				id = "generic"
			end
			
			plm:EmitAction("nzombies.powerup." .. id)
		end
	end)
end)

-- Player downed
hook.Add("PlayerDowned", "PVox_nZombies_Revive", function(ply)
	if IsPlayerValid(ply) then
		local plm = PVox:GetPlayerModule(ply)
		plm:EmitAction("nzombies.revive.downed")
	end
	
	timer.Simple(3, function()
		local ply2 = GetRandomValidPlayer(ply)
		
		if IsValid(ply2) then
			local plm = PVox:GetPlayerModule(ply2)
			plm:EmitAction("nzombies.revive.otherdowned")
		end
	end)
end)

-- Player killed
hook.Add("PlayerKilled", "PVox_nZombies_Revive", function(ply)
	local ply2 = GetRandomValidPlayer(ply)
	
	if IsValid(ply2) then
		local plm = PVox:GetPlayerModule(ply2)
		plm:EmitAction("nzombies.revive.dead")
	end
end)

-- Player being revived
hook.Add("PlayerBeingRevived", "PVox_nZombies_Revive", function(ply, revivor)
	if IsPlayerValid(revivor) then
		local plm = PVox:GetPlayerModule(revivor)
		plm:EmitAction("nzombies.revive.reviving")
	end
end)

-- Player revived
hook.Add("PlayerRevived", "PVox_nZombies_Revive", function(ply)
	if IsPlayerValid(ply) then
		local plm = PVox:GetPlayerModule(ply)
		plm:EmitAction("nzombies.revive.revived")
	end
end)

-- Electricity events
hook.Add("ElectricityOn", "PVox_nZombies_Power", function()
	timer.Simple(3, function()
		if nzRound:InProgress() then
			local ply = GetRandomValidPlayer()
			
			if IsValid(ply) then
				local plm = PVox:GetPlayerModule(ply)
				plm:EmitAction("nzombies.power.on")
			end
		end
	end)
end)

hook.Add("ElectricityOff", "PVox_nZombies_Power", function()
	timer.Simple(3, function()
		if nzRound:InProgress() then
			local ply = GetRandomValidPlayer()
			
			if IsValid(ply) then
				local plm = PVox:GetPlayerModule(ply)
				plm:EmitAction("nzombies.power.off")
			end
		end
	end)
end)

-- Facility interactions
hook.Add("OnPlayerBuyBox", "PVox_nZombies_Box", function(ply, gun)
	if IsPlayerValid(ply) then
		local plm = PVox:GetPlayerModule(ply)
		plm:EmitAction("nzombies.facility.randombox")
	end
end)

hook.Add("OnPlayerBuyWunderfizz", "PVox_nZombies_Wunderfizz", function(ply, perk)
	if IsPlayerValid(ply) then
		local plm = PVox:GetPlayerModule(ply)
		plm:EmitAction("nzombies.facility.wunderfizz")
	end
end)

hook.Add("OnPlayerBuyPackAPunch", "PVox_nZombies_Packapunch", function(ply, gun)
	if IsPlayerValid(ply) then
		local plm = PVox:GetPlayerModule(ply)
		plm:EmitAction("nzombies.facility.packapunch")
	end
end)

return MODULE

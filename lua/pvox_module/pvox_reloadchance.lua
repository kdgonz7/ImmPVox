if CLIENT then return end

local Chance = CreateConVar("pvox_reloadchance", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Chance to reload pvox modules")

hook.Add("PVOX_EmitAction", "CheckForReloadChance", function(player, action, override, _time)
    local chance_calc = math.random(1, Chance:GetInt()) == 1 or override or Chance:GetInt() == 0

    if action == "reload" then
        return chance_calc
    end

    return true
end)

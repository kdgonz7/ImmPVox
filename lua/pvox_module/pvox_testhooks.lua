if ! PVox then return end

-- hooks are only called
-- in their respective realm
if SERVER then
    hook.Add("PVOX_EmitAction", "PVOXEmitActionOverride", function(player, action, override, _time)
        -- actions can be ran multiple times a second, however they are throttled by
        -- the PVox system. So do take that into account when running these hooks.
    end)
end
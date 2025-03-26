AddCSLuaFile()

--* this is an example project
--* implementing a duck playermodel.
--* this implements the duck pack, 
--* and registers the duckie playermodel

PVox:ImplementModule("duck", function(ply)
	return {
		["print_name"] = "Duck",
		["description"] = "A duck. With 1 unique, high quality voice line. Made for testing, however, nice if you want a linear and easy to use duck voicelines.",
		["callouts"] = {
			["quack"] = {
				"playervox/modules/duck/quack_5.mp3",
			},
		},
		["actions"] = {
			-- one unique voice line
			-- QUAKCK
			["on_ready"] = {
				"playervox/modules/duck/quack_5.mp3",
			},
			["enemy_spotted"] = "on_ready",
			["enemy_killed"] = "on_ready",
			["take_damage"] = "on_ready",
			["no_ammo"] = "on_ready",
			["death"] = "on_ready",
			["frag_out"] = "on_ready",
			["confirm_kill"] = "on_ready",
			["reload"] = "on_ready",
			["switchtaunt"] = "on_ready",
			["inspect"] = "on_ready",
		}
	}
end)

PVox:ImplementCC("en-US", "duck", "playervox/modules/duck/quack_5.mp3", "Quack")
PVox:EnableCC("duck")

PVox:RegisterPlayerModel("models/player/duckie2/duckie.mdl", "duck")
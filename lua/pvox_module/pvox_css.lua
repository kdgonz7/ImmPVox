AddCSLuaFile()

if ! PVox then return end

PVox:ImplementModule("css-ct", function(ply)
	return {
		["print_name"] = "Counter Strike: Source Counter-Terrorists Operator",
		["actions"] = {
			["on_ready"] = {
				"playervox/modules/css/letsgo.wav",
				"playervox/modules/css/locknload.wav",
				"playervox/modules/css/moveout.wav",
			},

			["enemy_spotted"] = {
				"playervox/modules/css/ct_enemys.wav",
			},

			["enemy_killed"] = PVox:GenerateSimilarNames(3, "playervox/modules/css/enemy_down", "wav", false, ""),

			["take_damage"] = {
				"playervox/modules/css/ct_backup.wav",
			},

			["no_ammo"] = {},

			["death"] = PVox:GenerateSimilarNames(6, "playervox/modules/css/death", "wav", false, ""),

			["frag_out"] = {
				"playervox/modules/css/ct_fireinhole.wav",
			},

			["confirm_kill"] = {
				"playervox/modules/css/dropped_him.wav",
			},

			["reload"] = {
				"playervox/modules/css/ct_coverme.wav",
			},

			["switchtaunt"] = {},

			["inspect"] = PVox:GenerateSimilarNames(1, "playervox/modules/css/taunt", "wav", false),
		},
	}
end)

PVox:RegisterPlayerModel("models/player/guerilla.mdl", "css-ct")
PVox:RegisterPlayerModel("models/player/leet.mdl", "css-ct")
PVox:RegisterPlayerModel("models/player/phoenix.mdl", "css-ct")
PVox:RegisterPlayerModel("models/player/riot.mdl", "css-ct")
PVox:RegisterPlayerModel("models/player/swat.mdl", "css-ct")
PVox:RegisterPlayerModel("models/player/urban.mdl", "css-ct")
PVox:RegisterPlayerModel("models/player/gasmask.mdl", "css-ct")
PVox:RegisterPlayerModel("models/player/arctic.mdl", "css-ct")

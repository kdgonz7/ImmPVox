--! beware, here be dragons! 

hook.Add( "AddToolMenuCategories", "Cat232", function()
	spawnmenu.AddToolCategory( "Options", "PVOX", "#PVOX" )
end )

hook.Add( "PopulateToolMenu", "Cat232", function()
	---
	---@param panel DForm
	spawnmenu.AddToolMenuOption( "Options", "PVOX", "PVOXSettings", "#Regular Settings", "", "", function( panel )
		panel:Clear()

		if LocalPlayer():IsSuperAdmin() then
			panel:CheckBox( "PVOX Enabled", "pvox_enabled" )
			panel:ControlHelp( "Should the PVOX system be enabled?" )

			panel:CheckBox( "Use Player Model Binds", "pvox_useplayermodelbinds" )
			panel:ControlHelp( "Should your presets be dependent on the playermodel you spawn with?" )

			panel:CheckBox("Localize Damage", "pvox_localizedamage")
			panel:ControlHelp( "(ONLY WORKS FOR SUPPORTED MODULES) Enables specified limbs being called instead of the general take_damage module. This requires the developers to have e.g. damage_head, damage_rightleg, etc." )

			panel:CheckBox("Specify Entity on killed and damage calls", "pvox_specifyotherentity")
			panel:ControlHelp( "(ONLY WORKS FOR SUPPORTED MODULES) Enables specific entity voice lines. e.g. instead of enemy_killed it will use e.g. soldier_killed, antlion_killed, etc." )

			panel:CheckBox("Only call kill-confirms once", "pvox_senddamageonce")
			panel:ControlHelp( "Throttles shooting dead bodies to having it call out only once." )

			panel:CheckBox("Enable CC (Closed Captions)", "pvox_useclosedcaptioning")
			panel:ControlHelp( "Enables printing audio files to the chat, from a player, as they're being played. Similar to Counter-Strike games." )

			panel:TextEntry("Localization Language", "pvox_gl_localizationlang")
			panel:ControlHelp( "The GLOBAL language for PVOX CC. This IS A SERVER SIDE VALUE. Defaults to en-US, and different languages can depend on how the module implements them." )
		end
	end )

	---@param panel DForm
	spawnmenu.AddToolMenuOption( "Options", "PVOX", "PVOXDebug", "#Debug Settings", "", "", function( panel )
		panel:Clear()
		if LocalPlayer():IsSuperAdmin() then
			panel:CheckBox( "Allow Notes", "pvox_allownotes" )
			panel:ControlHelp("Allows PVox to send server-side notes. They usually appear in the console, in the form of [PVox] <MESSAGE>.")
			panel:CheckBox( "Suppress Warnings", "pvox_suppresswarnings" )
			panel:ControlHelp("Suppresses PVox warnings. Good if you want a silent terminal, but recommended to be on if you want to debug PVOX.")
		end
	end )

	---@param panel DForm
	spawnmenu.AddToolMenuOption( "Options", "PVOX", "PVOXPatches", "#Server Patches", "", "", function( panel )
		panel:Clear()
		panel:ControlHelp("Patches are similar to modules, in that they implement code that originally wasn't in PVox before. They work by being separated branches of code via a condition, that runs if they're checked off. This allows for these console variables to control the behaviour of PVox, without having to mess with the core VOX pipeline.")
		panel:ControlHelp("")
		if LocalPlayer():IsSuperAdmin() then
			panel:CheckBox("Reload Chances", "pvox_patch_reload")
			panel:ControlHelp("This patch reworks the reload code to add a random chance to callout a reload, as opposed to having a callout on every single reload press.")

			panel:NumSlider("Reload Chance", "pvox_patch_reload_chance", 1, 100, 0)
			panel:ControlHelp("How rare should it be to callout a reload?")

			panel:NumSlider("Global Action RNG", "pvox_global_rng", 1, 100, 0)
			panel:ControlHelp("How rare should it be to callout anything in general? Note this makes the reload chance go up tenfold, and only one option should be selected. 1 disables the system entirely")

			panel:CheckBox("VOX-Specific Footstep SFX", "pvox_patch_footsteps")
			panel:ControlHelp("This patch implements footstep sounds that can be added by the VOX preset as opposed to the default footstep sounds. (NOTE: This may not be comptaible with EVERYTHING)")

			panel:CheckBox("Extended Actions", "pvox_patch_extended_action")
			panel:ControlHelp("Enables extended action calls. Adds actions like `use`, `jump`, and `melee-kill`")

			panel:NumSlider("Footstep Global Volume", "pvox_patch_footsteps_gl_footstepvolume", 0, 511, 0)
			panel:ControlHelp("How loud do you want footsteps to be?")
		end
	end )

	---@param panel DForm
	spawnmenu.AddToolMenuOption( "Options", "PVOX", "PVOXVOX", "#VOX Controls", "", "", function( panel )
		panel:Clear()
		
		panel:Button("Change Preset", "pvox_menu")
	end )
end )

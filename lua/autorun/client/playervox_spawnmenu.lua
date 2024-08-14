	hook.Add( "AddToolMenuCategories", "Cat232", function()
		spawnmenu.AddToolCategory( "Options", "PVOX", "#PVOX" )
	end )

	hook.Add( "PopulateToolMenu", "Cat232", function()
		---
		---@param panel DForm
		spawnmenu.AddToolMenuOption( "Options", "PVOX", "PVOXSettings", "#Settings", "", "", function( panel )
			panel:ClearControls()

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

				panel:TextEntry("Localization Language", "pvox_localizationlang")
				panel:ControlHelp( "The GLOBAL language for PVOX CC. This IS A SERVER SIDE VALUE. Defaults to en-US, and different languages can depend on how the module implements them." )
			end
		end )
		---@param panel DForm
		spawnmenu.AddToolMenuOption( "Options", "PVOX", "PVOXDebug", "#Debug", "", "", function( panel )
			panel:ClearControls()
			if LocalPlayer():IsSuperAdmin() then
				panel:CheckBox( "Allow Notes", "pvox_allownotes" )
				panel:ControlHelp("Allows PVox to send server-side notes. They usually appear in the console, in the form of [PVox] <MESSAGE>.")
				panel:CheckBox( "Suppress Warnings", "pvox_suppresswarnings" )
				panel:ControlHelp("Suppresses PVox warnings. Good if you want a silent terminal, but recommended to be on if you want to debug PVOX.")
			end
		end )
		---@param panel DForm
		spawnmenu.AddToolMenuOption( "Options", "PVOX", "PVOXVOX", "#VOX", "", "", function( panel )
			panel:ClearControls()
			
			---@class DComboBox
			local Combo = panel:ComboBox( "PVOX Preset", "" )
			panel:ControlHelp( "Change your current PVOX preset. Will stop on respawn unless Use 'Player Model Binds' is off." )

			for k, v in pairs(PVox.Modules) do
				Combo:AddChoice( k )
			end

			Combo.OnSelect = function( self, index, value )
				net.Start("PVox_ChangePlayerPreset")
				net.WriteString(value)
				net.SendToServer()

				notification.AddLegacy("PVOX Preset set to " .. value .. "!", NOTIFY_GENERIC, 6)
			end

			Combo:SetValue( "combine-soldier" )
		end )
	end )

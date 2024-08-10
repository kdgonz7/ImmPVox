	hook.Add( "AddToolMenuCategories", "Cat232", function()
		spawnmenu.AddToolCategory( "Options", "PVOX", "#PVOX" )
	end )

	hook.Add( "PopulateToolMenu", "Cat232", function()
		spawnmenu.AddToolMenuOption( "Options", "PVOX", "PVOXSettings", "#PVOX Settings", "", "", function( panel )
			panel:ClearControls()

			if LocalPlayer():IsSuperAdmin() then
			panel:CheckBox( "PVOX Enabled", "pvox_enabled" )
			panel:CheckBox( "Use Player Model Binds", "pvox_useplayermodelbinds" )
			end

			panel:ControlHelp( "Should your presets be dependent on the playermodel you spawn with?" )

			local Combo = panel:ComboBox( "PVOX Preset", "pvox_mypreset" )
			panel:ControlHelp( "Change your current PVOX preset. Will stop on respawn unless Use 'Player Model Binds' is off." )
			Combo:SetValue( "Presets" )

			for k, v in pairs(PVox.Modules) do
				Combo:AddChoice( k )
			end

			Combo.OnSelect = function( self, index, value )
				net.Start("PVox_ChangePlayerPreset")
				net.WriteString(value)
				net.SendToServer()

				notification.AddLegacy("PVOX Preset set to " .. value .. "!", NOTIFY_GENERIC, 6)
			end
		end )
	end )

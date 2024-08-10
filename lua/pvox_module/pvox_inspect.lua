--* Hi, world!
--* this it the first ever PVOX module.
--*
--* this module shows the simple workflow for calling client-side hooks.
--* it's a very straightforward way to do things, and it's not based
--* on any sort of complicated API, so anybody can easily make a simple module.
--*
--* it primarily relies on the Garry's Mod LUA API as opposed to a custom one.
--* note for beginners: store sound files in the sound folder, not the lua folder.
--*
--* also this module requires the PVox module
--*
--* for readability, modules are shared. Called in both 
--* the client realm as well as the server.
--*

AddCSLuaFile()

if SERVER then
	util.AddNetworkString("PVox_Inspect")
end

if ! PVox then
	-- for mods, this is recommended
	-- as it lets the user know the PVOX API is not
	-- installed. This is not required, but should be considered
	-- if you want to make an addon that scales easily to other environments
	-- as well as allows for easier error handling.
	Derma_Message("The PVOX Module API is not established! This could mean you do not have the PVox module installed.", "PVox Error", "OK")
end

if SERVER then
	-- we're using a singular net message here,
	-- there's a lot of other ways to do this
	-- this is the one i found the most efficient
	net.Receive("PVox_Inspect", function(len, ply)
		local pmod = PVox:GetModule(ply:GetNWString("vox_preset", "none"))
		pmod:EmitAction(ply, "inspect")
	end)
end

if CLIENT then
	hook.Add("KeyPress", "PVox_Inspect", function(ply, key)
		if input.IsKeyDown(KEY_F) then
			net.Start("PVox_Inspect")
			net.SendToServer()
		end
	end)
end

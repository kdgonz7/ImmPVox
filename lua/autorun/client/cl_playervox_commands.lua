concommand.Add("pv_changepreset", function(ply, cmd, args)
	net.Start("PVox_ChangePlayerPreset")
	net.WriteString(args[1])
	net.SendToServer()
end)

for _,v in pairs(file.Find("pvox_module/*.lua", "LUA")) do
	include("pvox_module/" .. v)
end

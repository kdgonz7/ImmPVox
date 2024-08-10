-- load client side modules. I think this is how it should go

if SERVER then
	return
end

local files = file.Find("pvox_module/*.lua", "LUA")

local log = function(v)
	MsgC(Color(0, 255, 0), "[PVox CLIENT]", Color(255, 255, 255), " " .. v .. "\n")
end

for _, v in pairs(files) do
	log("loading pvox_module/ on client: " .. v)
	log("pvox modules: " .. table.Count(PVox.Modules))
	include("pvox_module/" .. v)
end

---@diagnostic disable: missing-parameter
if SERVER then return end

local padding = 10

local basecol = Color(64, 64, 64, 64)

local circlebordercol = Color(255, 255, 255, 64)

local linebordercol = Color(255, 255, 255, 64)

local textcol = Color(255, 255, 255, 192)

local outlinetextcol = Color(25, 25, 25, 192)

local textspacing = 0.6

surface.CreateFont("pvox_radi", {
	font = "Anonymous Pro", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 25,
	weight = 100,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

local PVoxMenuOpen = false

local function drawFilledCircle(x, y, radius, seg)
	local cir = {}

	table.insert(cir, { x = x, y = y, u = 0.5, v = 0.5 })
	for i = 0, seg do
		local a = math.rad((i / seg) * -360)
		table.insert(cir,
			{
				x = x + math.sin(a) * radius,
				y = y + math.cos(a) * radius,
				u = math.sin(a) / 2 + 0.5,
				v = math.cos(a) /
					2 + 0.5
			})
	end

	local a = math.rad(0) -- This is need for non absolute segment counts
	table.insert(cir,
		{
			x = x + math.sin(a) * radius,
			y = y + math.cos(a) * radius,
			u = math.sin(a) / 2 + 0.5,
			v = math.cos(a) / 2 +
				0.5
		})

	surface.DrawPoly(cir)
end

local function DrawMenu()
	local ply = LocalPlayer()

	if ! IsValid(ply) then return end
	if ! ply:Alive() then return end

	if ! PVoxMenuOpen then return end

	local ply_mod = PVox:GetPlayerModule(ply)
	if ! ply_mod then return end

	local callout_sounds = ply_mod:GetCallouts()
	if ! callout_sounds then return end

	local callout_keys = table.GetKeys(callout_sounds)

	-- pvox note: it's easy to get callouts, since
	-- mods are client-side and server-side.
	table.sort(callout_keys, function(a, b)
		local val1 = a or tostring(a)
		local val2 = b or tostring(b)
		return val1 < val2
	end)

	local col = Color(54, 54, 54)
	local col2 = Color(54, 54, 54)

	local scrw, scrh = ScrW(), ScrH()

	local count = math.max(#callout_keys, 3)

	local arcdegrees = (360 / count) - padding

	local radius = math.min(scrw * 0.5 / 2, scrh * 0.75 / 1) * 0.75

	local d = 360

	local cursorx, cursory = input.GetCursorPos()

	local mouseangle = math.deg(math.atan2(cursorx - scrw / 2, cursory - scrh / 2))
	local mousedist = math.sqrt(math.pow(cursorx - scrw / 2, 2) + math.pow(cursory - scrh / 2, 2))

	mouseangle = mouseangle - 90

	if mouseangle < -180 then mouseangle = mouseangle + 360 end
	if mouseangle > 180 then mouseangle = mouseangle - 360 end

	input.SetCursorPos(math.cos(math.rad(mouseangle)) * math.min(mousedist, radius) + scrw / 2,
		-math.sin(math.rad(mouseangle)) * math.min(mousedist, radius) + scrh / 2)

	draw.NoTexture()

	surface.SetDrawColor(Color(col.r, col.g, col.b, basecol.a))

	drawFilledCircle(scrw / 2, scrh / 2, radius + 2, 64)

	for i = 0, 2 do
		-- surface.DrawCircle(scrw / 2, scrh / 2, innerradius - i, Color(col2.r, col2.g, col2.b, circlebordercol.a))
		-- surface.DrawCircle(scrw / 2, scrh / 2, radius + i, Color(col2.r, col2.g, col2.b, circlebordercol.a))
	end

	local textareawidth = math.abs(math.sin(math.rad(arcdegrees))) * radius * math.pow(textspacing, 2) * 1.5
	local textradius = radius * textspacing

	for i = 1, count do
		local cl = callout_keys[i]

		if ! cl then return end

		local text = callout_sounds[cl].name or cl or ""

		surface.SetFont("pvox_radi")

		local w = surface.GetTextSize(text)

		if w > textareawidth then
			text = string.sub(text, 1, string.len(text) - 3) .. "..."
			w = surface.GetTextSize(text)
			while w > textareawidth do
				text = string.sub(text, 1, string.len(text) - 4) .. "..."
				w = surface.GetTextSize(text)
			end
		end

		local rad = math.rad(d + arcdegrees * 0.66)

		draw.SimpleTextOutlined(text, "pvox_radi", scrw / 2 + math.cos(rad) * textradius,
			scrh / 2 - math.sin(rad) * textradius, textcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1,
			outlinetextcol)

		d = d - arcdegrees - padding

		surface.SetDrawColor(Color(col2.r, col2.g, col2.b, linebordercol.a))
		-- surface.DrawLine(scrw / 2 + math.cos(math.rad(d)) * innerradius,
		-- 	scrh / 2 - math.sin(math.rad(d)) * innerradius, scrw / 2 + math.cos(math.rad(d)) * radius,
		-- 	scrh / 2 - math.sin(math.rad(d)) * radius)
	end
end

-- hook.Add("HUDPaint", "PVox_Radial", DrawMenu)
hook.Add("HUDPaint", "0_shoulddraw", function()
	if PVoxMenuOpen then
		DrawMenu()
	end
end)

local function Radial()
	PVoxMenuOpen = !PVoxMenuOpen

	local ply = LocalPlayer()

	if PVoxMenuOpen then
		if ! IsValid(ply) then return end
		if ! ply:Alive() then return end

		gui.EnableScreenClicker(true)

		local m = PVox:GetPlayerModule(ply)
		if ! m then return end
		if ! m['callouts'] then return gui.EnableScreenClicker(false) end
		if #m['callouts'] == 0 then return gui.EnableScreenClicker(false) end
	else
		local mod = PVox:GetPlayerModule(ply)
		if ! mod then return end

		if ! IsValid(ply) then return end

		// get the callout sounds list and keys
		local Sounds = mod:GetCallouts()
		if ! Sounds then return end

		local Keys = table.GetKeys(Sounds)

		/* sort the keys */
		table.sort(Keys, function(a, b)
			local val1 = Sounds[a].name or tostring(a)
			local val2 = Sounds[b].name or tostring(b)
			return val1 < val2
		end)

		// screen width and height
		local scrw, scrh = ScrW(), ScrH()
		local radius = math.min(ScrW() * 0.5 / 2, ScrH() * 0.75 / 1) * 0.75
		local innerradius = radius / 8
		local cursorx, cursory = input.GetCursorPos()

		/* essentially rebuild the radius */
		local mouseangle = math.deg(math.atan2(cursorx - scrw / 2, cursory - scrh / 2))
		local mousedist = math.sqrt(math.pow(cursorx - scrw / 2, 2) + math.pow(cursory - scrh / 2, 2))

		local arcdegrees = (360 / #Keys)

		mouseangle = math.NormalizeAngle(360 - (mouseangle - 90) + arcdegrees)

		if mouseangle < 0 then mouseangle = mouseangle + 360 end

		if mousedist > innerradius then
			local i = math.floor(mouseangle / arcdegrees) + 1
			local k = Keys[i]

			if ! k then return end

			net.Start("PVOX_Callout")
			net.WriteString(k)
			net.SendToServer()
		end
	end
end

concommand.Add("+pvox_open_callout", function(ply, cmd, args)
	local PlayersModule = PVox:GetPlayerModule(ply)
	if ! PlayersModule then return end

	Radial()
	gui.EnableScreenClicker(true)
end)

concommand.Add("-pvox_open_callout", function(ply, cmd, args)
	local PlayersModule = PVox:GetPlayerModule(ply)
	if PlayersModule then
		Radial()
	end
	gui.EnableScreenClicker(false)

end)

-- Function to create the side panel
local keytable = {}

function KeyIsNumber(key)
	return key == KEY_1 or key == KEY_2 or key == KEY_3 or key == KEY_4 or key == KEY_5 or key == KEY_6 or key == KEY_7 or key == KEY_8 or key == KEY_9
end

local nt = {
	[1] = KEY_1,
	[2] = KEY_2,
	[3] = KEY_3,
	[4] = KEY_4,
	[5] = KEY_5,
	[6] = KEY_6,
	[7] = KEY_7,
	[8] = KEY_8,
	[9] = KEY_9
}

net.Receive("PVox_OpenCalloutPanel", function()
	if IsValid(calloutPanel) then
		calloutPanel:Remove()
		return
	end

	local callouts = net.ReadString()
	callouts = util.JSONToTable(callouts)

	PrintTable(callouts)

	calloutPanel = vgui.Create("DFrame")
	calloutPanel:SetTitle("Callout Menu")
	calloutPanel:SetSize(ScrW() * 0.5, ScrH() * 0.5)
	calloutPanel:Center()
	calloutPanel:SetDraggable(false)
	calloutPanel:ShowCloseButton(false)
	calloutPanel:SetVisible(true)
	calloutPanel:SetDeleteOnClose(true)
	calloutPanel:MakePopup()
	calloutPanel.Paint = function(self, w, h)
		draw.RoundedBox(5, 0, 0, w, h, Color(114, 114, 114))
		surface.SetDrawColor(255, 255, 255)
	end

	local i = 1

	for callout, _ in pairs(callouts) do
			local button = vgui.Create("DButton", calloutPanel)
			button:SetText(callout)
			button:SetSize(180, 30)
			button:SetPos(ScrW() * .15, 50 + (i - 1) * 40)
			button.Paint = function(self, w, h)
				surface.SetDrawColor(154, 154, 154)
				draw.RoundedBox(5, 0, 0, w, h, Color(126, 156, 247))
				surface.SetDrawColor(255, 255, 255)
			end
			button:SetFont("DermaLarge")
			button:SetTextColor(Color(248, 248, 248))
			-- make a button with a corresponding number on the keyboard
			keytable[nt[i]] = button:GetText()

			button.DoClick = function()
				net.Start("PVox_Callout")
				net.WriteString(button:GetText())
				net.SendToServer()

				calloutPanel:Remove()
			end

			if i > 9 then
				break
			end

			i = i + 1
	end
end)

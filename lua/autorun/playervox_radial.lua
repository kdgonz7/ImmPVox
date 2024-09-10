---@diagnostic disable: undefined-field
if SERVER then return end

local PVoxCalloutMenuOpen = false
local PVoxCalloutMenuOptions = {
    BoxColor = Color(36, 36, 36),
    BoxRadius = 12
}

local Options = {}
local Selected = 1

hook.Add("HUDPaint", "painta", function()
    local Us = LocalPlayer()

    if PVoxCalloutMenuOpen and Us:Alive() then
        local ScreenW = ScrW()
        local ScreenH = ScrH()
        local Base = { x = ScreenW * 0.05,  y = ScreenH * 0.3 }

        -- the menu is in the bottom left

        surface.SetTextPos(Base.x, Base.y)
        surface.SetTextColor(Color(255, 255, 255))
        surface.SetFont("PVox-Normal-HUD-Font")

        local m = PVox:GetPlayerModule(Us)

        if ! m then return end
        if ! m.callouts then return end
        if table.IsEmpty(m.callouts) then return end

        local pos = Base.y

        local i = 1

        local NewSize = {
            x = ScreenW * 0.20,
            y = ScreenH * 0.06,
        }

        local callouts_keys = table.GetKeys(m.callouts)

        table.sort(callouts_keys)

        for _, k in pairs(callouts_keys) do
            local Text = tostring(i) .. ". " .. k
            local TextX, TextY = surface.GetTextSize(Text)

            NewSize.y = NewSize.y + TextY

            /* we set the new size of the box to the text's width. It's greater than ours */
            if TextX > NewSize.x then
                NewSize.x = TextX * 1.3
            end

            i = i + 1
        end

        draw.RoundedBox(PVoxCalloutMenuOptions.BoxRadius, ScreenW * 0.03, ScreenH * 0.27, NewSize.x, NewSize.y, PVoxCalloutMenuOptions.BoxColor)
        
        i = 1

        -- k = callout name, v = callout table
        for _, k in pairs(callouts_keys) do
            local Text = tostring(i) .. ". " .. k

            if i == Selected then
                Text = "-> " .. Text

                surface.SetTextColor(Color(255, 214, 10))
            else
                surface.SetTextColor(color_white)
            end

            local _, TextSizey =  surface.GetTextSize(Text)

            pos = pos + TextSizey
            surface.DrawText(Text)
            surface.SetTextPos(Base.x, pos)

            Options[i] = k

            i = i + 1
        end

        Options[i] = "Cancel"

    end
end)

hook.Add("PlayerBindPress", "fads", function(ply, bind, pressed)
    if ! PVoxCalloutMenuOpen then return end
    if ! pressed then return end
    
    if bind == "invnext" then
        Selected = Selected + 1

        if Selected > #Options - 1 then
            Selected = 1
        end

        return true
    elseif bind == "invprev" then
        Selected = Selected - 1

        if Selected < 1 then
            Selected = #Options - 1
        end

        return true
    end
end)

concommand.Add("+pvox_open_callout", function()
    PVoxCalloutMenuOpen = true
end)

concommand.Add("-pvox_open_callout", function()
    PVoxCalloutMenuOpen = false
    if Options[Selected] == nil then Selected = 1; return end


    net.Start("PVOX_Callout")
    net.WriteString(Options[Selected])
    net.SendToServer()

    Selected = 1

    Options = {}
end)

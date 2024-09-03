if SERVER then return end

local PVoxCalloutMenuOpen = false
local Options = {}
local Selected = 1

local KeysToNumbers = {
    [KEY_1] = 1,
    [KEY_2] = 2,
    [KEY_3] = 3,
    [KEY_4] = 4,
    [KEY_5] = 5,
    [KEY_6] = 6,
}

hook.Add("HUDPaint", "painta", function()
    if PVoxCalloutMenuOpen then
        local ScreenW = ScrW()
        local ScreenH = ScrH()
        local Base = { x = ScreenW * 0.1,  y = ScreenH * 0.6 }

        -- the menu is in the bottom left

        surface.SetFont("HudDefault")
        surface.SetTextPos(Base.x, Base.y)
        surface.SetTextColor(Color(255, 255, 255))
        
        local m = PVox:GetPlayerModule(LocalPlayer())

        if ! m then return end
        if ! m.callouts then return end

        local pos = Base.y

        local i = 1
        -- k = callout name, v = callout table
        for k, v in pairs(m.callouts) do
            local Text = tostring(i) .. ". " .. k
            local _, TextSizey =  surface.GetTextSize(Text)
            if i == Selected then
                surface.SetTextColor(Color(255, 214, 10))
            else
                surface.SetTextColor(color_white)
            end
            
            pos = pos + TextSizey

            surface.DrawText(Text)
            surface.SetTextPos(Base.x, pos)

            Options[i] = k

            i = i + 1
        end
    end
end)

--- comments
hook.Add("PlayerBindPress", "fads", function(ply, bind, pressed)
    if ! PVoxCalloutMenuOpen then return end
    if ! pressed then return end

    if bind == "invnext" then
        Selected = Selected + 1
        if Selected > #Options then
            Selected = #Options
        end
        return true
    elseif bind == "invprev" then
        Selected = Selected - 1

        if Selected < 1 then
            Selected = 1
        end
        return true
    end
end)

concommand.Add("+pvox_open_callout", function()
    PVoxCalloutMenuOpen = true
end)

concommand.Add("-pvox_open_callout", function()
    PVoxCalloutMenuOpen = false
    
    if Options[Selected] == nil then return end

    net.Start("PVOX_Callout")
    net.WriteString(Options[Selected])
    net.SendToServer()
end)

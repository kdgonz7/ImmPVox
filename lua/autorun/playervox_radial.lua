if SERVER then return end

local LocalePlayer        = LocalPlayer()
local PVoxCalloutMenuOpen = false

local function panic(message)
    error(message)
end

-- a very simple result type.
--- @class Result
local Result = {
    __some = nil,
    __none = false,
}

function Result:Unwrap()
    if self:IsNone() then
        panic("tried to unwrap a None value")
    end
end

function Result:IsSome()
    return self.__some != nil and ! self.__none
end

function Result:IsNone()
    return self.__none == true and self.__some == nil
end

function Some(T)
    return Result {
        __some = T,
        __none = false
    }
end

function None()
    return Result {
        __some = nil,
        __none = true
    }
end

// settings for the radial HUD, this includes the padding, basecolor, linebordercolor (for traditional style like TFA, etc.)
local Settings = {
    Padding         = 10,                                 // the padding of the radial HUD
    CirclePadding   = 5,
    Segments        = 72,
    BaseColor       = Color(64, 64, 64, 64),    // 
    LineBorderColor = Color(255, 255, 255, 64),
    TextSpacing     = 0.6,
}

---Draws a filled circle
---@param x number
---@param y number
---@param rad number
---@param seg number
local function DrawCircleFill(x, y, rad, seg)
    local Circle = {}; table.insert(Circle, { x = x, y = y, u = 0.5, v = 0.5 })

    for i = 0, seg do
        local Arc = math.rad((i / seg) * -360)

        table.insert(Circle, {
            x = x + math.sin(Arc) * rad,
            y = y + math.cos(Arc) * rad,
			u = math.sin(Arc) / 2 + 0.5,
			v = math.cos(Arc) / 2 + 0.5
        })
    end

    local ZeroCount = math.rad( 0 )

    table.insert(Circle, {
        x = x + math.sin(ZeroCount) * rad,
        y = y + math.cos(ZeroCount) * rad,
        u = math.sin(ZeroCount) / 2 + 0.5,
        v = math.cos(ZeroCount) / 2 + 0.5
    })

    surface.DrawPoly(Circle) -- draw the circle after creation
end

hook.Add("HUDPaint", "draw_radial_hud", function()
    if ! PVoxCalloutMenuOpen then return end
    if ! IsValid(LocalePlayer) or ! LocalePlayer:Alive() then
        return
    end

    local PlayerModule = PVox:GetPlayerModule(LocalePlayer)
    local ScreenWidth, ScreenHeight = ScrW(), ScrH()
    local CursorXPos, CursorYPos = input.GetCursorPos()

    if ! PlayerModule then
        return
    end -- player doesn't have a module

    local Callouts = PlayerModule:GetCallouts()

    if ! Callouts then
        return
    end

    Callouts = table.GetKeys( Callouts ) -- override previous value with the keys
    
    local CalloutsCount = math.max(#Callouts, 3)
    local ArcCallouts = (360 / CalloutsCount) - Settings.Padding -- convert the amount of callouts into an arc, where each call out gets an equal amount of space
    local Radius = math.min(ScreenWidth * 0.5 / 2, ScreenHeight * 0.75 / 1) * 0.75

    local MouseAngle = (math.deg(math.atan2(CursorXPos - ScreenWidth / 2, CursorYPos - ScreenHeight / 2))) - 90
    local MouseDistance = math.sqrt(
        math.pow(CursorXPos - ScreenWidth / 2, 2) +
        math.pow(CursorYPos - ScreenHeight / 2, 2)
    )

    -- get back in the circle
    if MouseAngle < -180 then MouseAngle = MouseAngle + 360 end
    if MouseAngle > 180 then MouseAngle = MouseAngle - 360 end

    input.SetCursorPos(
        math.cos(math.rad(MouseAngle) * math.min(MouseDistance, Radius)) + ScreenWidth / 2,
        -math.sin(math.rad(MouseAngle)) * math.min(MouseDistance, Radius) + ScreenHeight / 2
    )

    draw.NoTexture()
    surface.SetDrawColor(Settings.BaseColor)

    DrawCircleFill(ScreenWidth / 2, ScreenHeight / 2, Radius + Settings.CirclePadding, Settings.Segments)

    local ArcSin = math.sin(math.rad(ArcCallouts))
    local Spacing = math.pow(Settings.TextSpacing, 2) * 1.5
    
    local TAreaSurface = math.abs(ArcSin) * Radius * Spacing
    local TAreaRadius  = Radius * Settings.TextSpacing
end)

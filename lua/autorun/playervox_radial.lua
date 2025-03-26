---@diagnostic disable: undefined-field
if SERVER then return end

local PVoxCalloutMenuOpen = false
local PVoxCalloutMenuAlpha = 0
local TargetAlpha = 0
local CenterPos = { x = 0, y = 0 }
local MenuRadius = 300
local ItemRadius = 40
local OpenAnimation = 0
local SelectedAngle = 0
local HoverItem = nil

local Options = {}
local Selected = 1

local MenuColors = {
    Background = Color(36, 36, 36, 180),
    OuterRing = Color(65, 105, 225, 200),
    InnerCircle = Color(20, 20, 20, 220),
    Selected = Color(255, 214, 10),
    Text = Color(255, 255, 255),
    Hover = Color(100, 180, 255, 100)
}

local function GetCirclePoint(angle, radius)
    return {
        x = math.cos(math.rad(angle)) * radius,
        y = math.sin(math.rad(angle)) * radius
    }
end

local function Lerp(t, a, b)
    return a + (b - a) * t
end

hook.Add("HUDPaint", "PVox_RadialMenu", function()
    local Us = LocalPlayer()
    if not Us:Alive() then return end

    -- Animate menu alpha
    local approachSpeed = FrameTime() * 6
    PVoxCalloutMenuAlpha = Lerp(approachSpeed, PVoxCalloutMenuAlpha, TargetAlpha)
    
    -- Animate opening
    if PVoxCalloutMenuOpen then
        OpenAnimation = Lerp(approachSpeed, OpenAnimation, 1)
        TargetAlpha = 255
    else
        OpenAnimation = Lerp(approachSpeed, OpenAnimation, 0)
        TargetAlpha = 0
    end
    
    if PVoxCalloutMenuAlpha < 1 and not PVoxCalloutMenuOpen then return end

    local ScreenW, ScreenH = ScrW(), ScrH()
    CenterPos = { x = ScreenW / 2, y = ScreenH / 2 }
    
    local m = PVox:GetPlayerModule(Us)
    if not m or not m.callouts or table.IsEmpty(m.callouts) then return end

    -- Prepare callout options
    if table.IsEmpty(Options) then
        local callouts_keys = table.GetKeys(m.callouts)
        table.sort(callouts_keys)
        Options = callouts_keys
        table.insert(Options, "Cancel")
    end
    
    -- Draw outer circle
    local outerRingColor = ColorAlpha(MenuColors.OuterRing, PVoxCalloutMenuAlpha)
    local scaledRadius = MenuRadius * OpenAnimation
    
    -- Draw blur under the menu
    draw.BlurredCircle(CenterPos.x, CenterPos.y, scaledRadius + 30, ColorAlpha(MenuColors.Background, PVoxCalloutMenuAlpha * 0.5))
    
    -- Draw outer ring with glow
    surface.SetDrawColor(outerRingColor)
    local segments = 64
    for i = 1, segments do
        local angle1 = (i-1) * 360 / segments
        local angle2 = i * 360 / segments
        
        local p1 = GetCirclePoint(angle1, scaledRadius)
        local p2 = GetCirclePoint(angle2, scaledRadius)

        surface.DrawLine(   
            CenterPos.x + p1.x, CenterPos.y + p1.y,
            CenterPos.x + p2.x, CenterPos.y + p2.y
        )
    end
    
    -- Draw inner circle
    draw.Circle(CenterPos.x, CenterPos.y, scaledRadius * 0.3, ColorAlpha(MenuColors.InnerCircle, PVoxCalloutMenuAlpha))
    
    -- Draw menu title
    draw.SimpleTextOutlined(
        "PVOX",
        "PVox-Normal-HUD-Font",
        CenterPos.x,
        CenterPos.y,
        ColorAlpha(MenuColors.Text, PVoxCalloutMenuAlpha),
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER,
        1,
        ColorAlpha(Color(0, 0, 0), PVoxCalloutMenuAlpha)
    )
    
    -- Draw menu items in a circle
    local itemCount = #Options
    
    -- start on the cancel instead of the first element
    Selected = itemCount
    
    
    local angleStep = 360 / itemCount
    
    -- Get mouse angle for hover detection
    local mouseX, mouseY = gui.MouseX(), gui.MouseY()
    local mouseVec = Vector(mouseX - CenterPos.x, mouseY - CenterPos.y, 0)
    local mouseAngle = math.deg(math.atan2(mouseVec.y, mouseVec.x))
    if mouseAngle < 0 then mouseAngle = mouseAngle + 360 end
    
    -- Get mouse distance for hover detection
    local mouseDist = mouseVec:Length()
    HoverItem = nil
    
    if PVoxCalloutMenuOpen and mouseDist < scaledRadius + ItemRadius and mouseDist > scaledRadius * 0.4 then
        -- Find hovered item based on angle
        for i = 1, itemCount do
            local itemAngle = (i - 1) * angleStep
            local angleDiff = math.abs(((mouseAngle - itemAngle + 180) % 360) - 180)

            if angleDiff < angleStep / 2 then
                HoverItem = i
                break
            end
        end
    end
    
    -- Animate selected angle
    local targetAngle = (Selected - 1) * angleStep
    SelectedAngle = Lerp(approachSpeed * 2, SelectedAngle, targetAngle)
    
    for i = 1, itemCount do
        local angle = (i - 1) * angleStep
        local isSelected = (Selected == i)
        local isHovered = (HoverItem == i)
        
        -- Calculate item position
        local scaleFactor = isSelected and 1.2 or (isHovered and 1.1 or 1)
        local itemPos = GetCirclePoint(angle, scaledRadius * OpenAnimation)
        local x, y = CenterPos.x + itemPos.x, CenterPos.y + itemPos.y
        
        -- Draw connecting line from center
        surface.SetDrawColor(ColorAlpha(isSelected and MenuColors.Selected or MenuColors.OuterRing, PVoxCalloutMenuAlpha * 0.5))
        surface.DrawLine(CenterPos.x, CenterPos.y, x, y)
        
        -- Draw item circle
        local itemColor = isSelected and MenuColors.Selected or (isHovered and MenuColors.Hover or MenuColors.Background)
        draw.Circle(x, y, ItemRadius * scaleFactor * OpenAnimation, ColorAlpha(itemColor, PVoxCalloutMenuAlpha))
        
        -- Draw item text
        local text = Options[i]
        if i == itemCount then text = "✕ " .. text end
        
        draw.SimpleTextOutlined(
            text,
            "PVox-Radial-HUD-Font",
            x,
            y,
            ColorAlpha(isSelected and MenuColors.Selected or MenuColors.Text, PVoxCalloutMenuAlpha),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER,
            1,
            ColorAlpha(Color(0, 0, 0), PVoxCalloutMenuAlpha)
        )
        
        -- Draw selection indicator
        if isSelected then
            draw.Circle(x, y, ItemRadius * 1.3 * OpenAnimation, ColorAlpha(MenuColors.Selected, PVoxCalloutMenuAlpha * 0.3))
        end
    end
    
    local selPos = GetCirclePoint(SelectedAngle, scaledRadius + 20)
    draw.SimpleTextOutlined(
        "▶",
        "PVox-Normal-HUD-Font",
        CenterPos.x + selPos.x,
        CenterPos.y + selPos.y,
        ColorAlpha(MenuColors.Selected, PVoxCalloutMenuAlpha),
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER,
        1,
        ColorAlpha(Color(0, 0, 0), PVoxCalloutMenuAlpha)
    )
end)

hook.Add("PlayerBindPress", "PVox_RadialMenuControls", function(ply, bind, pressed)
    if not PVoxCalloutMenuOpen then return end
    if not pressed then return end
    
    if bind == "invnext" then
        Selected = Selected % #Options + 1
        return true
    elseif bind == "invprev" then
        Selected = Selected - 1
        if Selected < 1 then Selected = #Options end
        return true
    end
end)

hook.Add("Think", "PVox_RadialMenuMouse", function()
    if not PVoxCalloutMenuOpen then return end
    
    if HoverItem and input.IsMouseDown(MOUSE_LEFT) then
        Selected = HoverItem
    end

end)

function draw.Circle(x, y, radius, color)
    local segments = 32
    local poly = {}
    
    for i = 0, segments do
        local angle = math.rad((i / segments) * -360)
        poly[i + 1] = {
            x = x + math.sin(angle) * radius,
            y = y + math.cos(angle) * radius
        }
    end
    
    surface.SetDrawColor(color)
    draw.NoTexture()
    surface.DrawPoly(poly)
end

-- Blurred circle for background effect
function draw.BlurredCircle(x, y, radius, color)
    render.SetScissorRect(x - radius, y - radius, x + radius, y + radius, true)

    surface.SetDrawColor(color)
    surface.SetMaterial(Material("pp/blurscreen"))

    render.SetScissorRect(0, 0, 0, 0, false)

    draw.Circle(x, y, radius, color)
end

concommand.Add("+pvox_open_callout", function()
    PVoxCalloutMenuOpen = true
    gui.EnableScreenClicker(true)
end)

concommand.Add("-pvox_open_callout", function()
    PVoxCalloutMenuOpen = false
    gui.EnableScreenClicker(false)
    
    if Options[Selected] and Selected <= #Options then
        net.Start("PVOX_Callout")
        net.WriteString(Options[Selected])
        net.SendToServer()
    end
    
    Selected = 1
    Options = {}
end)

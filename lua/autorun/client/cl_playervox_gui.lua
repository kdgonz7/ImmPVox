-- cl_playervox_gui.lua
-- A modern Derma GUI for PVox modules

local PANEL = {}
local COLOR_THEME = {
    background = Color(40, 40, 40, 255),
    header = Color(30, 30, 30, 255),
    accent = Color(50, 150, 255, 255),
    text = Color(230, 230, 230, 255),
    textDark = Color(180, 180, 180, 255),
    hover = Color(60, 60, 60, 255),
    moduleBackground = Color(45, 45, 45, 255),
    moduleActive = Color(55, 145, 235, 100),
}

-- Initialize the fonts we'll use
surface.CreateFont("PVox_Title", {
    font = "Roboto",
    size = 24,
    weight = 500,
    antialias = true,
})

surface.CreateFont("PVox_ModuleTitle", {
    font = "Roboto",
    size = 18,
    weight = 500,
    antialias = true,
})

surface.CreateFont("PVox_Text", {
    font = "Roboto",
    size = 16,
    weight = 400,
    antialias = true,
})

-- Main frame for PVox GUI
local function OpenPVoxGUI()
    if IsValid(PVoxFrame) then PVoxFrame:Remove() end
    
    PVoxFrame = vgui.Create("DFrame")
    PVoxFrame:SetSize(900, 500)
    PVoxFrame:SetTitle("")
    PVoxFrame:SetDraggable(true)
    PVoxFrame:ShowCloseButton(false)
    PVoxFrame:Center()
    PVoxFrame:MakePopup()
    
    PVoxFrame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, COLOR_THEME.background)
        draw.RoundedBoxEx(8, 0, 0, w, 40, COLOR_THEME.header, true, true, false, false)
        draw.SimpleText("PVox Configuration", "PVox_Title", 20, 20, COLOR_THEME.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    -- Close Button
    local closeButton = vgui.Create("DButton", PVoxFrame)
    closeButton:SetSize(30, 30)
    closeButton:SetPos(PVoxFrame:GetWide() - 35, 5)
    closeButton:SetText("")
    closeButton.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and COLOR_THEME.accent or COLOR_THEME.header)
        draw.SimpleText("✕", "PVox_Text", w/2, h/2, COLOR_THEME.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeButton.DoClick = function()
        PVoxFrame:Close()
    end
    
    -- Create a scroll panel to contain modules
    local scrollPanel = vgui.Create("DScrollPanel", PVoxFrame)
    scrollPanel:Dock(FILL)
    scrollPanel:DockMargin(10, 50, 10, 10)
    
    -- Customize the scroll bar
    local sbar = scrollPanel:GetVBar()
    sbar:SetWide(8)
    function sbar:Paint(w, h) end
    function sbar.btnUp:Paint(w, h) end
    function sbar.btnDown:Paint(w, h) end
    function sbar.btnGrip:Paint(w, h)
        draw.RoundedBox(4, 2, 0, w-4, h, COLOR_THEME.accent)
    end
    
    local modules = {}

    -- todo: expand this part because we want to allow for descriptions and shit
    for moduleName, moduleValue in pairs(PVox.Modules) do
        table.insert(modules, {
            name = moduleValue.name or moduleValue.print_name or moduleName,
            description = moduleValue.description or "a generic PVOX module.",
            enabled = true, -- todo: wtf? always'll be true.
        })
    end
    
    -- Create module panels
    for i, module in ipairs(modules) do
        local modulePanel = vgui.Create("DPanel", scrollPanel)
        modulePanel:SetTall(90)
        modulePanel:Dock(TOP)
        modulePanel:DockMargin(0, 0, 0, 10)
        modulePanel:SetBackgroundColor(COLOR_THEME.moduleBackground)
        
        modulePanel.Paint = function(self, w, h)
            local borderColor = module.enabled and COLOR_THEME.moduleActive or COLOR_THEME.moduleBackground
            draw.RoundedBox(6, 0, 0, w, h, borderColor)
            draw.RoundedBox(5, 1, 1, w-2, h-2, COLOR_THEME.moduleBackground)
        end
        
        local moduleTitle = vgui.Create("DLabel", modulePanel)
        moduleTitle:SetFont("PVox_ModuleTitle")
        moduleTitle:SetText(module.name)
        moduleTitle:SetTextColor(COLOR_THEME.text)
        moduleTitle:SetPos(15, 10)
        moduleTitle:SizeToContents()
        
        local moduleDesc = vgui.Create("DLabel", modulePanel)
        moduleDesc:SetFont("PVox_Text")
        moduleDesc:SetText(module.description)
        moduleDesc:SetTextColor(COLOR_THEME.textDark)
        moduleDesc:SetPos(15, 35)
        moduleDesc:SetSize(400, 20)
        
        local toggleButton = vgui.Create("DButton", modulePanel)
        toggleButton:SetSize(80, 30)
        toggleButton:SetText("")
        toggleButton:Dock(RIGHT)
        toggleButton:DockMargin(0, 30, 20, 30)


        toggleButton.Paint = function(self, w, h)
            local bgColor = module.enabled and COLOR_THEME.accent or COLOR_THEME.hover
            if self:IsHovered() then
                bgColor = ColorAlpha(bgColor, 200)
            end
            
            draw.RoundedBox(4, 0, 0, w, h, bgColor)
            draw.SimpleText(module.enabled and "Enabled" or "Disabled", "PVox_Text", w/2, h/2, COLOR_THEME.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        toggleButton.DoClick = function()
            -- module.enabled = not module.enabled
            -- Add your actual toggle logic here, for example:
            -- PVox.ToggleModule(module.name, module.enabled)
            surface.PlaySound("ui/buttonclick.wav")
        end
    end
    
    -- version info
    local footerPanel = vgui.Create("DPanel", PVoxFrame)
    footerPanel:SetTall(30)
    footerPanel:Dock(BOTTOM)
    footerPanel:DockMargin(10, 0, 10, 5)
    footerPanel.Paint = function(self, w, h)
        draw.SimpleText(PVOX_VersionStr, "PVox_Text", 5, h/2, COLOR_THEME.textDark, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

-- Register the console command to open the GUI
concommand.Add("pvox_menu", OpenPVoxGUI)

-- Override the chat command to open the menu
hook.Add("OnPlayerChat", "PVoxMenuCommand", function(ply, text)
    if ply == LocalPlayer() and string.lower(text) == "!pvox" then
        OpenPVoxGUI()
        return true
    end
end)

-- Add to context menu
hook.Add("PopulateToolMenu", "PVoxConfigMenu", function()
    spawnmenu.AddToolMenuOption("Options", "Player", "PVoxConfig", "PVox Settings", "", "", function(panel)
        panel:ClearControls()
        local button = panel:Button("Open PVox Configuration")
        button.DoClick = OpenPVoxGUI
    end)
end)

print("PVox GUI module loaded!")
--[[
    Key Bindings Module
    Listens for key presses and executes actions
]]

if SERVER then return end

local function IsInputFocused()
    local panel = vgui.GetKeyboardFocus()
    return IsValid(panel) and panel:IsVisible()
end

hook.Add("PlayerButtonDown", "ArtoRP.Keys.Press", function(ply, button)
    if button == KEY_G then
        if not IsFirstTimePredicted() then return end
        if ply ~= LocalPlayer() then return end
        
        -- Check for GUI/Typing
        if ply:IsTyping() or IsInputFocused() or gui.IsGameUIVisible() or gui.IsConsoleVisible() then return end
        
        -- Execute
        RunConsoleCommand("artorp_drop")
    end
end)

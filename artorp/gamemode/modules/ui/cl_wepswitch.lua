--[[
    UI Module - Weapon Selector (Lua VGUI Version)
    Refined Design: Animated, Smooth, High Fidelity
]]

if SERVER then return end

-- Configuration
local config = {
    hideDefault = true,
    stayOpenTime = 4,
    cardWidth = 220,
    cardHeight = 100, -- More compact, cleaner
    spacing = 15,
    topMargin = 30,
}

-- Fonts
surface.CreateFont("ArtoWepName", {
    font = "Roboto",
    size = 24,
    weight = 800,
    antialias = true,
})

surface.CreateFont("ArtoWepDesc", {
    font = "Roboto",
    size = 14,
    weight = 500,
    antialias = true,
    shadow = false,
})

-- Hide Default
if config.hideDefault then
    hook.Add("HUDShouldDraw", "ArtoRP.WepSel.HideDefault", function(name)
        if name == "CHudWeaponSelection" then return false end
    end)
end

-- Variables
local container = nil
local closeTimer = 0
local isOpen = false
local selectedIndex = 1
local weaponList = {}

-- Styles
local colors = {
    bg = Color(15, 15, 20, 240),
    activeBg = Color(255, 140, 0), -- Orange
    text = Color(200, 200, 200),
    activeText = Color(15, 15, 20), -- Dark text on orange
    glow = Color(255, 140, 0, 50)
}

-- Gradient Material
local grad = Material("gui/gradient")
local gradDown = Material("gui/gradient_down")

local function CreateMenu()
    if IsValid(container) then container:Remove() end
    
    container = vgui.Create("Panel")
    container:SetSize(ScrW(), config.cardHeight + 100)
    container:SetPos(0, config.topMargin)
    container:SetVisible(false)
end

local function RefreshWeapons()
    if not IsValid(container) then CreateMenu() end
    
    container:Clear()
    
    local ply = LocalPlayer()
    weaponList = ply:GetWeapons()
    
    table.sort(weaponList, function(a, b)
        local slotA = (a.Slot or 0) * 10 + (a.SlotPos or 0)
        local slotB = (b.Slot or 0) * 10 + (b.SlotPos or 0)
        return slotA < slotB
    end)
    
    if #weaponList == 0 then return end
    
    -- Centering logic
    local totalW = (#weaponList * config.cardWidth) + ((#weaponList - 1) * config.spacing)
    local startX = (ScrW() / 2) - (totalW / 2)
    
    for k, wep in ipairs(weaponList) do
        local card = vgui.Create("DPanel", container)
        card:SetSize(config.cardWidth, config.cardHeight)
        card:SetPos(startX + (k-1)*(config.cardWidth + config.spacing), 0)
        card.animProgress = 0 -- For animation
        
        -- Icon (Moved to right side for style)
        local icon = vgui.Create("SpawnIcon", card)
        icon:SetSize(80, 80)
        icon:SetPos(config.cardWidth - 90, 10)
        
        -- Model check
        local model = wep:GetModel()
        if not model or model == "" or model == "models/error.mdl" then
            -- Fallback to a generic icon or keep blank/hidden to avoid huge ERROR text
            -- Trying to get spawn icon from class if model fails
            icon:SetModel("models/weapons/w_pistol.mdl") -- Temp fallback or hide
            icon:SetVisible(false) -- Hide if no model to avoid ugly red ERROR
        else
            icon:SetModel(model)
        end
        
        icon:SetMouseInputEnabled(false)
        icon:SetAlpha(150) -- Dim default
        
        card.Paint = function(s, w, h)
            local isActive = (k == selectedIndex)
            
            -- Animation
            local target = isActive and 1 or 0
            s.animProgress = Lerp(FrameTime() * 15, s.animProgress or 0, target)
            
            -- ... (Visuals same)
            
            -- Draw Shadow
            if s.animProgress > 0.1 then
                surface.SetDrawColor(0,0,0, s.animProgress * 100)
                draw.NoTexture()
                surface.DrawTexturedRectRotated(w/2, h/2 + 10, w, h, 0)
            end
            
            -- Draw BG
            draw.RoundedBox(6, 0, 0, w, h, Color(15, 15, 20, 240 + (s.animProgress * 10)))
            
            -- Draw Active Glow Overlay
            if s.animProgress > 0.01 then
                surface.SetMaterial(gradDown)
                surface.SetDrawColor(255, 140, 0, s.animProgress * 255)
                surface.DrawTexturedRect(0, 0, w, h)
                
                surface.SetDrawColor(255, 255, 255, s.animProgress * 50)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            
            -- Icon Alpha Update
            if IsValid(icon) then
                icon:SetAlpha(150 + (s.animProgress * 105)) 
            end
            
            -- Text
            local textColor = Color(
                200 + (s.animProgress * 55), 
                200 + (s.animProgress * 55), 
                200 + (s.animProgress * 55)
            )
            
            -- Name
            local name = string.upper(wep:GetPrintName() or wep:GetClass())
            if string.len(name) > 13 then name = string.sub(name, 1, 13) .. ".." end
            
            draw.SimpleText(name, "ArtoWepName", 15, 25, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Slot Info (Fixed)
            local slotNum = (wep.Slot and (wep.Slot + 1)) or 1 -- Default to 1 if nil
            draw.SimpleText("SLOT " .. slotNum, "ArtoWepDesc", 15, 50, Color(255, 140, 0, 100 + (s.animProgress * 155)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Selection Indicator Bar
            if s.animProgress > 0.01 then
                surface.SetDrawColor(255, 255, 255, s.animProgress * 255)
                surface.DrawRect(0, h-4, w * s.animProgress, 4)
            end
        end
    end
end

local function OpenSelector(forceIndex)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    weaponList = ply:GetWeapons()
    if #weaponList == 0 then return end
    
    -- Rebuild to ensure freshness
    RefreshWeapons()
    
    if not isOpen then
        if not forceIndex then
            local active = ply:GetActiveWeapon()
            for k, wep in ipairs(weaponList) do
                if wep == active then
                    selectedIndex = k
                    break
                end
            end
        end
    end
    
    if forceIndex then selectedIndex = forceIndex end
    
    isOpen = true
    closeTimer = CurTime() + config.stayOpenTime
    container:SetVisible(true)
    
    ply:EmitSound("buttons/lightswitch2.wav", 30, 100) -- Crisp scroll click
end

local function SelectWeapon()
    if not isOpen then return end
    
    local wep = weaponList[selectedIndex]
    if IsValid(wep) then
        input.SelectWeapon(wep)
    end
    
    isOpen = false
    if IsValid(container) then container:SetVisible(false) end
    
    -- Sound removed per request
    -- PlayEquipSound() 
end

-- Input Hook
hook.Add("PlayerBindPress", "ArtoRP.WepSel.Input", function(ply, bind, pressed)
    if not pressed then return end
    
    if bind == "invnext" then
        if not isOpen then OpenSelector() end
        selectedIndex = selectedIndex + 1
        if selectedIndex > #weaponList then selectedIndex = 1 end
        OpenSelector(selectedIndex) 
        return true
    elseif bind == "invprev" then
        if not isOpen then OpenSelector() end
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then selectedIndex = #weaponList end
        OpenSelector(selectedIndex)
        return true
    elseif bind == "+attack" then
        if isOpen then
            SelectWeapon()
            return true
        end
    end
end)

hook.Add("Think", "ArtoRP.WepSel.Think", function()
    if isOpen and CurTime() > closeTimer then
        isOpen = false
        if IsValid(container) then container:SetVisible(false) end
    end
end)

hook.Add("InitPostEntity", "ArtoRP.WepSel.Init", function()
    CreateMenu()
end)

CreateMenu()

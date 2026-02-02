--[[
    UI Module - Pickup History (Notifications)
    Replaces the default GMod pickup history with ArtoRP Style
]]

if SERVER then return end

-- Configuration
local config = {
    x = ScrW() - 300,
    y = ScrH() - 400, -- Start above ammo HUD essentially, stacking UP or DOWN? Usually down.
    width = 280,
    height = 40,
    spacing = 5,
    duration = 5,
    font = "ArtoPickupFont"
}

-- Fonts
surface.CreateFont("ArtoPickupFont", {
    font = "Rajdhani",
    size = 20,
    weight = 600,
    antialias = true,
})

surface.CreateFont("ArtoPickupCount", {
    font = "Roboto",
    size = 24,
    weight = 500,
    antialias = true,
})

-- Queue
local pickupQueue = {} -- { text, type, count, time, alpha }

-- Hook into GM functions to capture events preventing default drawing
function GM:HUDWeaponPickedUp(wep)
    if not IsValid(wep) then return end
    local name = wep.PrintName or wep:GetPrintName() or wep:GetClass()
    table.insert(pickupQueue, {
        text = string.upper(name),
        type = "weapon",
        count = 1,
        time = CurTime() + config.duration,
        alpha = 0,
        y = 0
    })
end

function GM:HUDItemPickedUp(itemName)
    table.insert(pickupQueue, {
        text = string.upper(language.GetPhrase(itemName)),
        type = "item",
        count = 1,
        time = CurTime() + config.duration,
        alpha = 0,
        y = 0
    })
end

function GM:HUDAmmoPickedUp(itemName, count)
    -- Check if we can merge with last
    local last = pickupQueue[#pickupQueue]
    if last and last.text == string.upper(language.GetPhrase(itemName)) and last.time > CurTime() then
        last.count = last.count + count
        last.time = CurTime() + config.duration -- Refresh
        last.alpha = 0 -- Flash effect?
    else
        table.insert(pickupQueue, {
            text = string.upper(language.GetPhrase(itemName)),
            type = "ammo",
            count = count,
            time = CurTime() + config.duration,
            alpha = 0,
            y = 0
        })
    end
end

-- Override default drawing
hook.Add("HUDDrawPickupHistory", "ArtoRP.Pickup.HideDefault", function()
    return false
end)

-- Draw Logic
hook.Add("HUDPaint", "ArtoRP.Pickup.Draw", function()
    local x = config.x
    local startY = ScrH() * 0.7 -- Height positioning
    
    -- Cleanup
    for k, v in ipairs(pickupQueue) do
        if v.time < CurTime() then
            -- Fade out animation state could be handled here logic-wise
            -- but for simple removal:
            if v.expiryAlpha and v.expiryAlpha < 0.05 then
                table.remove(pickupQueue, k)
            end
        end
    end
    
    local currentY = startY
    
    for k, v in ipairs(pickupQueue) do
        -- Animation Logic
        local timeLeft = v.time - CurTime()
        
        -- Entrance fade-in
        if not v.entered then
            v.alpha = Lerp(FrameTime() * 10, v.alpha, 255)
            if v.alpha > 250 then v.entered = true end
        end
        
        -- Exit fade-out
        local alpha = v.alpha
        if timeLeft < 0.5 then
            alpha = (timeLeft / 0.5) * 255
            v.expiryAlpha = alpha
        end
        if alpha < 0 then alpha = 0 end
        
        -- Draw Background (Glass)
        draw.RoundedBox(4, x, currentY, config.width, config.height, Color(15, 15, 20, alpha * 0.9))
        
        -- Draw Accent Bar (Left side)
        local barColor = Color(255, 255, 255)
        if v.type == "weapon" then barColor = Color(255, 140, 0) -- Orange
        elseif v.type == "ammo" then barColor = Color(0, 150, 255) -- Blue
        elseif v.type == "item" then barColor = Color(0, 255, 100) -- Green
        end
        
        draw.RoundedBoxEx(4, x, currentY, 4, config.height, Color(barColor.r, barColor.g, barColor.b, alpha), true, false, true, false)
        
        -- Draw Text
        local textX = x + 15
        draw.SimpleText(v.text, "ArtoPickupFont", textX, currentY + config.height/2, Color(220, 220, 220, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        -- Draw Count
        if v.count > 0 and v.type == "ammo" then
            draw.SimpleText("+" .. v.count, "ArtoPickupCount", x + config.width - 10, currentY + config.height/2, Color(255, 255, 255, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        
        -- Stack up
        currentY = currentY - (config.height + config.spacing)
    end
end)

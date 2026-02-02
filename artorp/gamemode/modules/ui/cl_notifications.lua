--[[
    UI Module - Notifications
    Replaces the default GMod notification system with ArtoRP style.
]]

if SERVER then return end

-- Notifications Queue
local queue = {}

-- Config
local config = {
    x = ScrW() - 290, -- Top Right aligned
    startY = 250, -- Starting Y position (Below Wanted HUD area)
    w = 280,
    h = 50, -- Height per notification
    spacing = 10, -- Spacing between notifications
    font = "ArtoNotifyFont"
}

-- Fonts
surface.CreateFont("ArtoNotifyFont", {
    font = "Rajdhani",
    size = 20,
    weight = 600,
    antialias = true
})

-- Icons (Cached)
local icons = {
    [NOTIFY_GENERIC] = Material("icon16/information.png"),
    [NOTIFY_ERROR] = Material("icon16/exclamation.png"),
    [NOTIFY_UNDO] = Material("icon16/arrow_undo.png"),
    [NOTIFY_HINT] = Material("icon16/lightbulb.png"),
    [NOTIFY_CLEANUP] = Material("icon16/bin.png")
}
-- Fallback icon
local defaultIcon = Material("icon16/application.png")

-- Colors
local typeColors = {
    [NOTIFY_GENERIC] = Color(0, 150, 255),
    [NOTIFY_ERROR] = Color(255, 60, 60),
    [NOTIFY_UNDO] = Color(255, 180, 0),
    [NOTIFY_HINT] = Color(50, 220, 100),
    [NOTIFY_CLEANUP] = Color(255, 100, 50)
}

-- 1. Override the Default Function
function notification.AddLegacy(text, type, length)
    local col = typeColors[type] or typeColors[NOTIFY_GENERIC]
    local icon = icons[type] or defaultIcon
    
    local entry = {
        text = text,
        type = type,
        color = col,
        icon = icon,
        time = CurTime() + (length or 5),
        alpha = 0,
        animX = 50 -- Slide in var
    }
    
    -- Insert at top
    table.insert(queue, 1, entry)
    
    -- Play Sound
    if type == NOTIFY_ERROR then
        surface.PlaySound("buttons/button10.wav")
    else
        surface.PlaySound("buttons/lightswitch2.wav")
    end
end

-- 2. Override Progress (Simple text fallback for now, rarely used)
function notification.AddProgress(id, text, fraction)
    -- We can just route this to legacy for simplicity in this style
    -- Or ignore fraction. 
    -- Ideally we'd have a separate progress bar UI, but for now let's spam less.
end

function notification.Kill(id)
    -- No-op
end

-- 3. Draw Hook
hook.Add("HUDPaint", "ArtoRP.Notifications.Draw", function()
    local currentY = config.startY
    
    for k, v in ipairs(queue) do
        -- Expiry
        local timeLeft = v.time - CurTime()
        if timeLeft <= 0 then
            -- Fade out fast
            v.alpha = Lerp(FrameTime() * 10, v.alpha, 0)
            if v.alpha < 5 then
                table.remove(queue, k)
            end
        else
            -- Fade In
            v.alpha = Lerp(FrameTime() * 10, v.alpha, 255)
            v.animX = Lerp(FrameTime() * 10, v.animX, 0)
        end
        
        -- Draw
        if v.alpha > 1 then
            local x = config.x + v.animX
            local alphaMul = v.alpha / 255
            
            -- Background (Dark Glass)
            draw.RoundedBox(4, x, currentY, config.w, config.h, Color(15, 15, 20, 245 * alphaMul))
            
            -- Border (Colored)
            surface.SetDrawColor(v.color.r, v.color.g, v.color.b, 255 * alphaMul)
            surface.DrawOutlinedRect(x, currentY, config.w, config.h, 1)
            
            -- Icon Background Box (Left Accent)
            draw.RoundedBoxEx(4, x, currentY, 40, config.h, Color(v.color.r, v.color.g, v.color.b, 20 * alphaMul), true, false, true, false)
            
            -- Icon
            surface.SetDrawColor(255, 255, 255, 255 * alphaMul)
            surface.SetMaterial(v.icon)
            surface.DrawTexturedRect(x + 12, currentY + (config.h/2) - 8, 16, 16)
            
            -- Text
            if v.text then
                -- Wrap check could go here, but preserving simple text for now
                -- Truncate if too long
                local tx = v.text
                if string.len(tx) > 35 then tx = string.sub(tx, 1, 32) .. "..." end
                
                draw.SimpleText(tx, config.font, x + 50, currentY + (config.h/2), Color(230, 230, 230, 255 * alphaMul), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            
            currentY = currentY + config.h + config.spacing
        end
    end
end)

-- Hide Default
hook.Add("HUDShouldDraw", "ArtoRP.HideDefaultNotifs", function(name)
    if name == "CHudNotifications" then return false end
end)

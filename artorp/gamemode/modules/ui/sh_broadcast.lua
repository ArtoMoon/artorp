--[[
    UI Module - Broadcast (Global Announcements)
    Admin command: /duyuru <msg> or /announce <msg>
]]

if SERVER then
    util.AddNetworkString("ArtoRP.Broadcast")

    -- Add the command to sv_commands logic later or just hook here simply
    -- Hooking into PlayerSay is easiest if we don't want to mess with the Command structure yet
    hook.Add("PlayerSay", "ArtoRP.Broadcast.Command", function(ply, text)
        local lower = string.lower(text)
        if string.sub(lower, 1, 8) == "/duyuru " or string.sub(lower, 1, 10) == "/announce " then
            if not ply:IsSuperAdmin() then 
                ply:ChatPrint("[ArtoRP] You do not have permission!")
                return "" 
            end
            
            local msg = string.sub(text, string.find(text, " ") + 1)
            if msg and msg ~= "" then
                net.Start("ArtoRP.Broadcast")
                net.WriteString(msg)
                net.WriteString(ply:Nick()) -- Sender
                net.Broadcast()
            end
            return "" -- Hide chat
        end
    end)
    return
end

-- Client Side
local broadcastQueue = {}
local isDrawing = false
local currentMsg = nil

net.Receive("ArtoRP.Broadcast", function()
    local text = net.ReadString()
    local who = net.ReadString()
    
    table.insert(broadcastQueue, {text = text, sender = who, time = CurTime() + 7})
end)

surface.CreateFont("ArtoBroadcastTitle", {
    font = "Rajdhani", size = 40, weight = 800, antialias = true
})
surface.CreateFont("ArtoBroadcastText", {
    font = "Rajdhani", size = 28, weight = 500, antialias = true
})

hook.Add("HUDPaint", "ArtoRP.Broadcast.Draw", function()
    if #broadcastQueue == 0 then return end
    
    -- Pick first
    local active = broadcastQueue[1]
    
    if CurTime() > active.time then
        -- Expire
        table.remove(broadcastQueue, 1)
        return
    end
    
    -- Calc Transparency
    local timeLeft = active.time - CurTime()
    local alpha = 255
    
    -- Fade In (First 0.5s)
    local elapsed = 7 - timeLeft
    if elapsed < 0.5 then
        alpha = (elapsed / 0.5) * 255
    end
    
    -- Fade Out (Last 0.5s)
    if timeLeft < 0.5 then
        alpha = (timeLeft / 0.5) * 255
    end
    
    local w, h = ScrW(), ScrH()
    local boxW, boxH = 800, 150
    local centerX, centerY = w/2, h * 0.2 -- Top center
    
    -- Draw Blur Background (Glass)
    draw.RoundedBox(8, centerX - boxW/2, centerY, boxW, boxH, Color(10, 10, 14, 240 * (alpha/255)))
    
    -- Border
    surface.SetDrawColor(255, 140, 0, 100 * (alpha/255))
    surface.DrawOutlinedRect(centerX - boxW/2, centerY, boxW, boxH, 2)
    
    -- Header Bar
    draw.RoundedBoxEx(8, centerX - boxW/2, centerY, boxW, 40, Color(255, 140, 0, 200 * (alpha/255)), true, true, false, false)
    draw.SimpleText("SERVER ANNOUNCEMENT", "ArtoBroadcastTitle", centerX, centerY + 20, Color(0,0,0, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Sender
    draw.SimpleText("From: " .. active.sender, "ArtoBroadcastText", centerX - boxW/2 + 20, centerY + boxH - 25, Color(150, 150, 150, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    
    -- Message
    -- Wrapping text manually or use DrawText
    local wrapped = string.upper(active.text) -- Style choice
    draw.DrawText(wrapped, "ArtoBroadcastText", centerX, centerY + 60, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
    
end)

--[[
    Server Module - Admin & VIP System (Separated)
]]

if CLIENT then return end

if CLIENT then return end
 
function ArtoRP.SaveData()
    local data = {
        ranks = {},
        vips = {},
        warnings = ArtoRP.Warnings
    }
    
    -- Load existing if possible to preserve offline
    if file.Exists("artorp_data.txt", "DATA") then
        local old = util.JSONToTable(file.Read("artorp_data.txt", "DATA"))
        if old then 
            data.ranks = old.ranks -- Merge partials if needed, simplfied here
            -- Actually we rebuild ranks/vips from online, but warnings must persist fully.
            -- So let's rely on ArtoRP.Warnings being fully loaded at start.
        end
    end
    
    -- Update online players
    for _, ply in ipairs(player.GetAll()) do
        -- Rank
        local g = ply:GetUserGroup()
        if g == "superadmin" or g == "admin" or g == "mod" then
            data.ranks[ply:SteamID()] = g
        else
            data.ranks[ply:SteamID()] = nil 
        end
        
        -- VIP
        if ply:GetNW2Bool("ArtoRP_IsVIP", false) then
            data.vips[ply:SteamID()] = true
        else
            data.vips[ply:SteamID()] = nil
        end
    end
    
    file.Write("artorp_data.txt", util.TableToJSON(data))
end

-- Hook Join
hook.Add("PlayerInitialSpawn", "ArtoRP.Admin.LoadData", function(ply)
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        
        if file.Exists("artorp_data.txt", "DATA") then
            local json = file.Read("artorp_data.txt", "DATA")
            local data = util.JSONToTable(json)
            
            if data then
                local sid = ply:SteamID()
                
                -- Load Rank
                if data.ranks and data.ranks[sid] then
                    ply:SetUserGroup(data.ranks[sid])
                    print("[ArtoRP] Loaded rank " .. data.ranks[sid] .. " for " .. ply:Nick())
                end
                
                -- Load VIP
                if data.vips and data.vips[sid] then
                    ply:SetNW2Bool("ArtoRP_IsVIP", true)
                end
                
                -- Load Warnings (to Cache)
                if data.warnings then
                    ArtoRP.Warnings = data.warnings
                    if ArtoRP.Warnings[sid] then
                        ply:SetNWInt("ArtoRP_Warns", #ArtoRP.Warnings[sid])
                    end
                end
            end
        end
        
        -- 2. Load from Config File (Priority Override)
        if ArtoRP.Config then
            local sid = ply:SteamID()
            if ArtoRP.Config.Admins and ArtoRP.Config.Admins[sid] then
                ply:SetUserGroup(ArtoRP.Config.Admins[sid])
                print("[ArtoRP] Config assigned " .. ArtoRP.Config.Admins[sid] .. " to " .. ply:Nick())
            end
            
            if ArtoRP.Config.VIPs and ArtoRP.Config.VIPs[sid] then
                ply:SetNW2Bool("ArtoRP_IsVIP", true)
                print("[ArtoRP] Config assigned VIP to " .. ply:Nick())
            end
        end
    end)
end)

-- Migration: Try to load old rank file if new one doesn't exist
if not file.Exists("artorp_data.txt", "DATA") and file.Exists("artorp_ranks.txt", "DATA") then
    local old = util.JSONToTable(file.Read("artorp_ranks.txt", "DATA"))
    local newData = { ranks = {}, vips = {} }
    for k,v in pairs(old) do
        if v == "vip" then 
            newData.vips[k] = true 
        else
            newData.ranks[k] = v
        end
    end
    file.Write("artorp_data.txt", util.TableToJSON(newData))
    print("[ArtoRP] Migrated old rank data to new system.")
end


-- Console Command: SET RANK
concommand.Add("artorp_setrank", function(ply, cmd, args)
    if IsValid(ply) then return end -- Console only
    
    local name = args[1]
    local rank = args[2]
    
    if not name or not rank then print("Usage: artorp_setrank <name> <superadmin|admin|user>") return end
    
    local target = nil
    for _, v in ipairs(player.GetAll()) do
        if string.find(string.lower(v:Nick()), string.lower(name)) then target = v break end
    end
    
    if not IsValid(target) then print("Player not found.") return end
    
    if rank == "superadmin" or rank == "admin" or rank == "mod" or rank == "user" then
        target:SetUserGroup(rank)
        print("Rank set to " .. rank)
        target:ChatPrint("[ArtoRP] Rank updated: " .. rank)
        ArtoRP.SaveData()
    else
        print("Invalid rank. Use: superadmin, admin, mod, user")
    end
end)

-- Global Warning API
ArtoRP.Warnings = ArtoRP.Warnings or {} -- [SteamID] = { {reason, admin, time} }

function ArtoRP.AddWarning(ply, adminName, reason)
    local sid = ply:SteamID()
    ArtoRP.Warnings[sid] = ArtoRP.Warnings[sid] or {}
    
    table.insert(ArtoRP.Warnings[sid], {
        admin = adminName,
        reason = reason,
        time = os.date("%d/%m %H:%M")
    })
    
    -- Update Count
    ply:SetNWInt("ArtoRP_Warns", #ArtoRP.Warnings[sid])
    
    ArtoRP.SaveData()
end

util.AddNetworkString("ArtoRP.OpenWarnUI")

-- Chat Command: !warns or !warn (Both Open UI)
hook.Add("PlayerSay", "ArtoRP.Chat.Warns", function(ply, text)
    local txt = string.lower(text)
    
    if txt == "!warn" or txt == "!warns" then
        local myWarns = ArtoRP.Warnings[ply:SteamID()] or {}
        net.Start("ArtoRP.OpenWarnUI")
        net.WriteTable(myWarns)
        net.Send(ply)
        return "" -- Hide command
    end
end)

-- Console Command: SET VIP
concommand.Add("artorp_setvip", function(ply, cmd, args)
    if IsValid(ply) then return end -- Console only
    
    local name = args[1]
    local state = args[2] -- 1 or 0
    
    if not name or not state then print("Usage: artorp_setvip <name> <1|0>") return end
    
    local target = nil
    for _, v in ipairs(player.GetAll()) do
        if string.find(string.lower(v:Nick()), string.lower(name)) then target = v break end
    end
    
    if not IsValid(target) then print("Player not found.") return end
    
    local isVip = (tonumber(state) == 1)
    target:SetNW2Bool("ArtoRP_IsVIP", isVip)
    
    if isVip then
        print("Gave VIP to " .. target:Nick())
        target:ChatPrint("[ArtoRP] You have been granted VIP status!")
    else
        print("Removed VIP from " .. target:Nick())
        target:ChatPrint("[ArtoRP] Your VIP status has been removed.")
    end
    SaveData()
end)

--[[
    Drop Command
]]

local function DropWeapon(ply)
    local wep = ply:GetActiveWeapon()
    
    if not IsValid(wep) then return end
    
    local class = wep:GetClass()
    
    -- Blacklist items you can't drop
    local blacklist = {
        ["weapon_physgun"] = true,
        ["gmod_tool"] = true,
        ["weapon_physcannon"] = true,
        ["weapon_fists"] = true,
        ["gmod_camera"] = true,
        ["arto_wallet"] = true
    }
    
    if blacklist[class] then
        ArtoRP.Notify(ply, 1, 4, "You cannot drop this weapon!")
        return
    end
    
    -- Calculate Drop Position
    local tr = util.TraceLine({
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * 50,
        filter = ply
    })
    
    local spawnPos = tr.HitPos + (tr.HitNormal * 10)
    print("[ArtoRP Debug] Attempting to drop: " .. class)
    print("[ArtoRP Debug] Spawn Position: " .. tostring(spawnPos))
    
    -- Create the weapon entity world-side
    local ent = ents.Create(class)
    if not IsValid(ent) then 
        print("[ArtoRP Debug] Failed to create entity!")
        return 
    end
    
    ent:SetPos(spawnPos)
    ent:SetAngles(ply:GetAngles())
    ent:Spawn()
    ent:Activate()
    print("[ArtoRP Debug] Entity Created: " .. tostring(ent))
    
    -- Prevent instant pickup
    ent.DropCooldown = CurTime() + 2 
    
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
    
    -- Remove from player
    ply:StripWeapon(class)
    
    ply:EmitSound("physics/metal/metal_box_break1.wav") -- Drop sound
    ArtoRP.Notify(ply, 0, 4, "Dropped " .. (wep.PrintName or class))
end

ArtoRP.RegisterCommand("drop", function(ply, args)
    DropWeapon(ply)
end, "Drop the weapon you are holding")

concommand.Add("artorp_drop", function(ply, cmd, args)
    DropWeapon(ply)
end)

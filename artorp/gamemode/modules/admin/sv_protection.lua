--[[
    Server Protection Module
    - Prevents non-admins from spawning props/entities.
]]

local function CheckAdmin(ply)
    -- Sadece SuperAdmin (Owner) prop spawn edebilir
    if ply:IsSuperAdmin() then
        return true
    end
    
    ply:ChatPrint("[ArtoRP] Only SuperAdmins can spawn things!")
    return false
end

hook.Add("PlayerSpawnProp", "ArtoRP.BlockSpawn.Prop", CheckAdmin)
hook.Add("PlayerSpawnEffect", "ArtoRP.BlockSpawn.Effect", CheckAdmin)
hook.Add("PlayerSpawnNPC", "ArtoRP.BlockSpawn.NPC", CheckAdmin)
hook.Add("PlayerSpawnObject", "ArtoRP.BlockSpawn.Object", CheckAdmin)
hook.Add("PlayerSpawnRagdoll", "ArtoRP.BlockSpawn.Ragdoll", CheckAdmin)
hook.Add("PlayerSpawnSENT", "ArtoRP.BlockSpawn.SENT", CheckAdmin)
hook.Add("PlayerSpawnSWEP", "ArtoRP.BlockSpawn.SWEP", CheckAdmin)
hook.Add("PlayerSpawnVehicle", "ArtoRP.BlockSpawn.Vehicle", CheckAdmin)

-- Prevent picking up players with Physgun (unless admin)
hook.Add("PhysgunPickup", "ArtoRP.BlockPickup", function(ply, ent)
    if ent:IsPlayer() then
        return ply:IsAdmin() or ply:IsSuperAdmin()
    end
end)

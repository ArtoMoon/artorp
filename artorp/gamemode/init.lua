--[[
    ArtoRP - Server Entry Point
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
-- Config is loaded inside shared.lua now
include("shared.lua")

-- Add shared modules that client needs
AddCSLuaFile("modules/jobs/sh_jobs.lua")
AddCSLuaFile("modules/economy/sh_money.lua")
include("modules/economy/sh_money.lua")
include("modules/economy/sv_shop.lua")

-- Add client UI files
AddCSLuaFile("modules/ui/cl_jobmenu.lua")
AddCSLuaFile("modules/ui/cl_hud.lua")
AddCSLuaFile("modules/ui/cl_chat.lua")
AddCSLuaFile("modules/ui/cl_wepswitch.lua")
AddCSLuaFile("modules/ui/cl_pickup.lua")
AddCSLuaFile("modules/ui/cl_scoreboard.lua")
AddCSLuaFile("modules/ui/cl_notifications.lua")
AddCSLuaFile("modules/ui/sh_broadcast.lua")
AddCSLuaFile("modules/ui/sh_admin.lua")
AddCSLuaFile("modules/ui/cl_thirdperson.lua")
AddCSLuaFile("modules/ui/cl_keys.lua")

include("modules/ui/sh_broadcast.lua") -- Server logic needs to run too
include("modules/ui/sh_admin.lua")
include("modules/admin/sv_admin.lua")
include("modules/admin/sv_protection.lua")


resource.AddFile("gamemodes/artorp/gamemode/content/sound/equ.mp3")
include("shared.lua")

-- Server-side initialization
function GM:Initialize()
    ArtoRP.Log("Server Init Complete.")
end

function GM:PlayerLoadout(ply)
    -- 1. Strip everything first
    ply:StripWeapons()
    ply:StripAmmo()
    
    -- 2. Give default tools
    ply:Give("weapon_fists") -- Hands
    ply:Give("arto_wallet")
    
    -- 3. Give Job Weapons
    local teamIndex = ply:Team()
    local jobData = ArtoRP.JobsByIndex and ArtoRP.JobsByIndex[teamIndex]
    
    if jobData and jobData.weapons then
        for _, wep in ipairs(jobData.weapons) do
            ply:Give(wep)
        end
    end
    
    -- 4. Switch to Fists or Physics gun
    ply:SelectWeapon("weapon_fists")
    
    return true -- Block default sandbox loadout
end

function GM:PlayerSetHands(ply, ent)
    local simplemodel = player_manager.TranslateToPlayerModelName(ply:GetModel())
    local info = player_manager.TranslatePlayerHands(simplemodel)
    
    if info then
        ent:SetModel(info.model)
        ent:SetSkin(info.skin)
        ent:SetBodyGroups(info.body)
    end
end

-- Prevent instant pickup of dropped weapons
function GM:PlayerCanPickupWeapon(ply, wep)
    if wep.DropCooldown and CurTime() < wep.DropCooldown then
        return false
    end
    return true
end

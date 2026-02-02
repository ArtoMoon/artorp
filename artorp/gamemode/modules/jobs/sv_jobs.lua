--[[
    Job System - Server
]]

local plyMeta = FindMetaTable("Player")

function plyMeta:ChangeJob(jobIndex)
    local jobData = ArtoRP.JobsByIndex[jobIndex]
    
    if not jobData then return false end
    
    -- Check limits
    local count = team.NumPlayers(jobIndex)
    if jobData.max > 0 and count >= jobData.max then
        self:ChatPrint("This job is full!")
        return false
    end
    
    -- VIP Check
    if jobData.vip then
        local isVIP = self:GetNW2Bool("ArtoRP_IsVIP", false)
        if not isVIP then
            self:ChatPrint("This job is for VIPs only!")
            return false
        end
    end
    
    self:SetTeam(jobIndex)
    self:SetModel(jobData.model)
    self:SetupHands() -- Force update hands to match model
    self:StripWeapons()
    self:Give("weapon_fists")
    self:Give("arto_wallet")
    
    -- Give job specific loadout if any
    if jobData.weapons then
        for _, wep in ipairs(jobData.weapons) do
            self:Give(wep)
        end
    end
    
    self:ChatPrint("You became a " .. jobData.name)
    return true
end

hook.Add("PlayerInitialSpawn", "ArtoRP.Jobs.SetDefault", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            ply:ChangeJob(TEAM_CITIZEN)
        end
    end)
end)

hook.Add("PlayerSpawn", "ArtoRP.Jobs.OnSpawn", function(ply)
    local jobData = ply:GetJobData()
    if jobData then
        ply:SetModel(jobData.model)
        ply:SetupHands() -- Force update hands on spawn
    end
end)

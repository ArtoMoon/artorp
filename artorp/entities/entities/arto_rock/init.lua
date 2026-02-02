AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    -- Placeholder Model - Modelin gelince burayi degistirecegiz
    -- self:SetModel("models/props_wasteland/rockgranite03a.mdl") 
    self:SetModel("models/props_wasteland/rockgranite03a.mdl") -- Temp
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false) -- Sabit dursun
    end
    
    self.HP = 100 -- Cani
    self.MaxHP = 100
end

function ENT:OnTakeDamage(dmginfo)
    -- Sadece kazma ile kirilabilir olsun istiyorsan:
    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()
    
    -- if IsValid(inflictor) and inflictor:GetClass() == "arto_pickaxe" then
        self.HP = self.HP - dmginfo:GetDamage()
        
        self:EmitSound("physics/concrete/concrete_impact_hard" .. math.random(1,3) .. ".wav")
        
        -- Effect
        local effectdata = EffectData()
        effectdata:SetOrigin(dmginfo:GetDamagePosition())
        effectdata:SetNormal(dmginfo:GetDamageForce():GetNormal())
        effectdata:SetMagnitude(2)
        effectdata:SetScale(1)
        effectdata:SetRadius(5)
        util.Effect("StoneImpact", effectdata)

        if self.HP <= 0 then
            self:BreakRock(attacker)
        end
    -- end
end

function ENT:BreakRock(ply)
    self:EmitSound("physics/concrete/concrete_break" .. math.random(2,3) .. ".wav")
    
    -- Maden ver (Ornek: Para veriyoruz simdilik)
    -- Burayi envanter sistemine baglayabiliriz
    if IsValid(ply) and ply:IsPlayer() then
        local reward = math.random(50, 150)
        ply:AddMoney(reward)
        ArtoRP.Notify(ply, 0, 4, "Maden kirdin ve $" .. reward .. " kazandin!")
    end
    
    self:Remove()
end

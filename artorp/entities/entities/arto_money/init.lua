AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props/cs_assault/money.mdl") -- Standard CSS Money model
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator, caller)
    if IsValid(activator) and activator:IsPlayer() then
        local amount = self:GetAmount()
        activator:AddMoney(amount)
        activator:ChatPrint("[ArtoRP] picked up $" .. amount)
        self:Remove()
    end
end

function ENT:SetAmount(amt)
    self.Amount = amt
    self:SetNWInt("Amount", amt) -- Sync for 3D2D display
end

function ENT:GetAmount()
    return self.Amount or 0
end

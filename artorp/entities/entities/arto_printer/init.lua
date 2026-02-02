AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_c17/consolebox01a.mdl") 
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    -- Explicitly set health for damage system
    self:SetMaxHealth(100)
    self:SetHealth(100) 
    
    self:SetStoredMoney(0)
    
    -- Defaults
    self:SetSpeedLevel(1)
    self:SetAmountLevel(1)
    self:SetCapacityLevel(1)
    
    self:SetIsOn(true)
    self:SetHeat(0)
    self:SetHasCooler(false)
    
    self:SetItemOwner(NULL) 
    
    -- Print Timer
    self.PrintTimer = 0
    self.SparkTimer = 0
    self.HeatTimer = 0
end

-- Hasar Alma ve Patlama
function ENT:OnTakeDamage(dmg)
    self:TakePhysicsDamage(dmg)
    
    local health = self:Health()
    local damage = dmg:GetDamage()
    
    self:SetHealth(health - damage)
    
    if self:Health() <= 0 then
        self:Destruct()
    end
end

function ENT:Destruct()
    local vPoint = self:GetPos()
    local effectdata = EffectData()
    effectdata:SetStart(vPoint)
    effectdata:SetOrigin(vPoint)
    effectdata:SetScale(1)
    util.Effect("Explosion", effectdata)
    
    self:Remove()
end

function ENT:Think()
    -- Heat Logic (Runs every 1 second independent of printing)
    if CurTime() > self.HeatTimer then
        local currentHeat = self:GetHeat()
        
        if self:GetIsOn() then
            -- Heating Up
            -- Cooler reduces heat gain significantly
            -- Base: +2/sec (50s to overheat), Cooler: +0.5/sec (200s to overheat)
            local gain = self:GetHasCooler() and 0.5 or 2
            
            local newHeat = currentHeat + gain
            if newHeat >= 100 then
                self:Destruct() -- BOOM
                return
            end
            self:SetHeat(newHeat)
        else
            -- Cooling Down
            local newHeat = currentHeat - 5
            if newHeat < 0 then newHeat = 0 end
            self:SetHeat(newHeat)
        end
        
        self.HeatTimer = CurTime() + 1
    end

    if not self:GetIsOn() then 
        self:NextThink(CurTime())
        return true 
    end

    -- Speed Level Logic
    local sLvl = 1
    if self.GetSpeedLevel then sLvl = self:GetSpeedLevel() end
    
    -- Base: 12s.  Lvl 1: 10s, Lvl 2: 8s, Lvl 3: 6s
    local interval = 12 - (sLvl * 2)
    if interval < 2 then interval = 2 end

    if CurTime() > self.PrintTimer then
        self:PrintMoney()
        self.PrintTimer = CurTime() + interval
    end
    
    if CurTime() > self.SparkTimer then
        self:EmitSound("ambient/levels/labs/equipment_printer_loop1.wav", 60, 100, 0.2)
        self.SparkTimer = CurTime() + (2.0 / sLvl) 
    end
    
    self:NextThink(CurTime())
    return true
end

function ENT:PrintMoney()
    local current = self:GetStoredMoney()
    
    local aLvl = self.GetAmountLevel and self:GetAmountLevel() or 1
    local cLvl = self.GetCapacityLevel and self:GetCapacityLevel() or 1
    
    -- Capacity: 2000 + (Lvl-1)*1000
    local max = 2000 + ((cLvl - 1) * 1000)
    
    if current >= max then return end 
    
    -- Amount: 100 * Level (100, 200, 300...)
    local amount = 100 * aLvl
    
    local newAmount = current + amount
    self:SetStoredMoney(newAmount)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    local money = self:GetStoredMoney()
    
    if money > 0 then
        -- Parayı oyuncuya ver
        if activator.AddMoney then
            activator:AddMoney(money)
        else
            -- Fallback (Eger metatable yuklenmediyse)
            activator:SetNW2Int("ArtoMoney", activator:GetNW2Int("ArtoMoney", 0) + money)
        end
        
        -- Bildirim
        ArtoRP.Notify(activator, 0, 3, "Collected $" .. money)
        self:EmitSound("items/ammo_pickup.wav")
        
        -- Zıplama Efekti (Feedback)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            -- Hafif yukarı zıplat
            phys:ApplyForceCenter(Vector(0, 0, 3000)) 
            -- Hafif döndür (Canlılık katar)
            phys:AddAngleVelocity(Vector(math.random(-100, 100), math.random(-100, 100), 0))
        end
        
        -- Sıfırla
        self:SetStoredMoney(0)
    else
        ArtoRP.Notify(activator, 1, 3, "Printer is empty!")
    end
end

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Money Printer"
ENT.Author = "ArtoRP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "ArtoRP"

-- Ayarlar
ENT.PrintAmount = 100 -- Her seferinde ne kadar basar?
ENT.PrintInterval = 10 -- Kaç saniyede bir basar?
ENT.MaxMoney = 2000 -- İçinde en fazla ne kadar birikir?

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "StoredMoney")
    
    -- Separate Upgrade Levels
    self:NetworkVar("Int", 1, "SpeedLevel")    -- Reduces time
    self:NetworkVar("Int", 2, "AmountLevel")   -- Increases money amount
    self:NetworkVar("Int", 3, "CapacityLevel") -- Increases max storage
    
    -- Heat System
    self:NetworkVar("Int", 4, "Heat")
    self:NetworkVar("Bool", 0, "IsOn")
    self:NetworkVar("Bool", 1, "HasCooler")
    
    self:NetworkVar("Entity", 0, "ItemOwner")
end

-- Economy Shop Module for ArtoRP
util.AddNetworkString("ArtoRP.Shop.BuyEntity")

local function SpawnEntity(ply, entClass, price)
    if not ply:CanAfford(price) then
        ArtoRP.Notify(ply, 1, 4, "You cannot afford this!")
        return 
    end
    
    -- Limit Check Logic
    local limit = 1 -- Default limit
    local group = ply:GetUserGroup()
    
    if group == "vip" or group == "admin" or group == "superadmin" then
        limit = 2
    end
    
    local count = 0
    for _, ent in ipairs(ents.FindByClass(entClass)) do
        -- Check custom ItemOwner field
        if ent.ItemOwner == ply then count = count + 1 end
    end
    
    if count >= limit then
        ArtoRP.Notify(ply, 1, 4, "Limit Reached! (Max: " .. limit .. ")")
        return
    end

    -- Take Money
    ply:AddMoney(-price)
    ArtoRP.Notify(ply, 0, 4, "Purchased " .. entClass .. " for $" .. price)
    
    -- Spawn Position Logic
    local tr = ply:GetEyeTraceNoCursor()
    local spawnPos = tr.HitPos + tr.HitNormal * 10
    
    if spawnPos:DistToSqr(ply:GetPos()) > 200 * 200 then
        spawnPos = ply:GetPos() + ply:GetForward() * 50 + Vector(0, 0, 10)
    end

    local ent = ents.Create(entClass)
    if not IsValid(ent) then return end
    
    ent:SetPos(spawnPos)
    ent:Spawn()
    ent:Activate()
    
    -- Set Owner (Handling both NetworkVar and custom field)
    ent.ItemOwner = ply 
    if ent.SetItemOwner then ent:SetItemOwner(ply) end
    
    -- CPPI Support (Only if exists)
    if ent.CPPISetOwner then ent:CPPISetOwner(ply) end 
end

net.Receive("ArtoRP.Shop.BuyEntity", function(len, ply)
    local index = net.ReadInt(32)
    
    if not ArtoRP.Config or not ArtoRP.Config.Entities then return end
    
    local item = ArtoRP.Config.Entities[index]
    if not item then return end
    
    SpawnEntity(ply, item.ent, item.price)
end)

-- Inventory Actions
util.AddNetworkString("ArtoRP.Inventory.Collect")
util.AddNetworkString("ArtoRP.Inventory.Sell")
util.AddNetworkString("ArtoRP.Inventory.UpgradeSpeed")
util.AddNetworkString("ArtoRP.Inventory.UpgradeAmount")
util.AddNetworkString("ArtoRP.Inventory.BuyCooler")
util.AddNetworkString("ArtoRP.Inventory.TogglePower")
util.AddNetworkString("ArtoRP.Inventory.Update")

-- Helper function to refresh client UI
local function RefreshClientInventory(ply)
    net.Start("ArtoRP.Inventory.Update")
    net.Send(ply)
end

net.Receive("ArtoRP.Inventory.Collect", function(len, ply)
    local ent = net.ReadEntity()
    local isOwner = IsValid(ent) and ((ent.GetItemOwner and ent:GetItemOwner() == ply) or (ent.ItemOwner == ply))
    
    if not IsValid(ent) or not isOwner then return end
    
    if ent.GetStoredMoney then
        local money = ent:GetStoredMoney()
        if money <= 0 then return end
        
        if ply.AddMoney then ply:AddMoney(money) end
        ent:SetStoredMoney(0)
        ArtoRP.Notify(ply, 0, 3, "Collected $" .. money .. " remotely.")
        RefreshClientInventory(ply) -- Refresh UI
    end
end)

net.Receive("ArtoRP.Inventory.Sell", function(len, ply)
    local ent = net.ReadEntity()
    local isOwner = IsValid(ent) and ((ent.GetItemOwner and ent:GetItemOwner() == ply) or (ent.ItemOwner == ply))
    
    if not IsValid(ent) or not isOwner then return end
    
    local price = 500
    if ply.AddMoney then ply:AddMoney(price) end
    
    ent:Remove()
    ArtoRP.Notify(ply, 0, 3, "Sold printer for $" .. price)
    RefreshClientInventory(ply) -- Refresh UI
end)

net.Receive("ArtoRP.Inventory.UpgradeSpeed", function(len, ply)
    local ent = net.ReadEntity()
    local isOwner = IsValid(ent) and ((ent.GetItemOwner and ent:GetItemOwner() == ply) or (ent.ItemOwner == ply))
    
    if not IsValid(ent) or not isOwner or not ent.GetSpeedLevel then return end
    
    local current = ent:GetSpeedLevel()
    if current >= 3 then ArtoRP.Notify(ply, 1, 3, "Max Speed reached!") return end
    
    local cost = 500 * current
    if not ply:CanAfford(cost) then ArtoRP.Notify(ply, 1, 3, "Need $" .. cost) return end
    
    ply:AddMoney(-cost)
    ent:SetSpeedLevel(current + 1)
    ArtoRP.Notify(ply, 0, 3, "Speed Upgraded!")
    RefreshClientInventory(ply) -- Refresh UI
end)

net.Receive("ArtoRP.Inventory.UpgradeAmount", function(len, ply)
    local ent = net.ReadEntity()
    local isOwner = IsValid(ent) and ((ent.GetItemOwner and ent:GetItemOwner() == ply) or (ent.ItemOwner == ply))
    
    if not IsValid(ent) or not isOwner or not ent.GetAmountLevel then return end
    
    local current = ent:GetAmountLevel()
    if current >= 3 then ArtoRP.Notify(ply, 1, 3, "Max Amount reached!") return end
    
    local cost = 750 * current
    if not ply:CanAfford(cost) then ArtoRP.Notify(ply, 1, 3, "Need $" .. cost) return end
    
    ply:AddMoney(-cost)
    ent:SetAmountLevel(current + 1)
    ArtoRP.Notify(ply, 0, 3, "Print Amount Upgraded!")
    RefreshClientInventory(ply) -- Refresh UI
end)

net.Receive("ArtoRP.Inventory.BuyCooler", function(len, ply)
    local ent = net.ReadEntity()
    local isOwner = IsValid(ent) and ((ent.GetItemOwner and ent:GetItemOwner() == ply) or (ent.ItemOwner == ply))
    
    if not IsValid(ent) or not isOwner then return end
    if ent:GetHasCooler() then ArtoRP.Notify(ply, 1, 3, "Already has a cooler!") return end
    
    local cost = 2000
    if not ply:CanAfford(cost) then ArtoRP.Notify(ply, 1, 3, "Cooler costs $" .. cost) return end
    
    ply:AddMoney(-cost)
    ent:SetHasCooler(true)
    ArtoRP.Notify(ply, 0, 3, "Cooler Installed! Heat generation reduced.")
    RefreshClientInventory(ply)
end)

net.Receive("ArtoRP.Inventory.TogglePower", function(len, ply)
    local ent = net.ReadEntity()
    local isOwner = IsValid(ent) and ((ent.GetItemOwner and ent:GetItemOwner() == ply) or (ent.ItemOwner == ply))
    
    if not IsValid(ent) or not isOwner then return end
    
    local newState = not ent:GetIsOn()
    ent:SetIsOn(newState)
    
    local status = newState and "ON" or "OFF"
    ArtoRP.Notify(ply, 0, 3, "Printer switched " .. status)
    RefreshClientInventory(ply)
end)

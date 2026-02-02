--[[
    Economy Module - Server Side
]]

local plyMeta = FindMetaTable("Player")

function plyMeta:SetMoney(amount)
    self:SetNW2Int("ArtoRP_Money", amount)
    self:SaveMoney() -- Placeholder for DB save
end

function plyMeta:AddMoney(amount)
    self:SetMoney(self:GetMoney() + amount)
end

function plyMeta:TakeMoney(amount)
    self:SetMoney(self:GetMoney() - amount)
end

function plyMeta:SaveMoney()
    -- Implement Database / SQLite saving here
    -- For now, we just log it
    -- ArtoRP.Log("Saved money for " .. self:Nick())
end

hook.Add("PlayerInitialSpawn", "ArtoRP.Economy.Load", function(ply)
    ply:SetMoney(1000) -- Starting Money
end)

-- Salary Loop
timer.Create("ArtoRP.Salary", 180, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local jobData = ply:GetJobData()
        if jobData and jobData.salary then
            local income = jobData.salary
            local isVIP = ply:GetNW2Bool("ArtoRP_IsVIP", false)
            
            -- VIP Bonus
            if isVIP then
                income = income + 50
            end
            
            ply:AddMoney(income)
            
            local msg = "Payday! You received $" .. income
            if isVIP then msg = msg .. " (VIP Bonus Included)" end
            
            ply:ChatPrint("[ArtoRP] " .. msg)
            ply:SendLua("surface.PlaySound('items/gift_drop.wav')")
        end
    end
end)

-- WALLET SYSTEM
util.AddNetworkString("ArtoRP.WalletAction")

net.Receive("ArtoRP.WalletAction", function(len, ply)
    local act = net.ReadString()
    local amount = net.ReadInt(32)
    
    if amount <= 0 then return end
    if not ply:CanAfford(amount) then
        ply:ChatPrint("[ArtoRP] You don't have enough money!")
        return
    end
    
    if act == "give" then
        -- Find player in front
        local tr = util.TraceHull({
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + ply:GetAimVector() * 100,
            filter = ply,
            mins = Vector(-10,-10,-10),
            maxs = Vector(10,10,10)
        })
        
        local target = tr.Entity
        if IsValid(target) and target:IsPlayer() then
            ply:TakeMoney(amount)
            target:AddMoney(amount)
            
            ply:ChatPrint("[ArtoRP] You gave $" .. amount .. " to " .. target:Nick())
            target:ChatPrint("[ArtoRP] " .. ply:Nick() .. " gave you $" .. amount)
            ply:EmitSound("items/gift_drop.wav")
        else
            ply:ChatPrint("[ArtoRP] No player in front of you!")
        end
        
    elseif act == "drop" then
        ply:TakeMoney(amount)
        
        -- Spawn Money Entity
        local money = ents.Create("arto_money") -- We need to create this entity!
        money:SetPos(ply:GetShootPos() + ply:GetAimVector() * 30)
        money:SetAmount(amount)
        money:Spawn()
        money:Activate()
        
        ply:ChatPrint("[ArtoRP] You dropped $" .. amount)
    end
end)

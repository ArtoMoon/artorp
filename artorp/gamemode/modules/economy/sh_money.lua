--[[
    Economy Module - Shared
]]

local plyMeta = FindMetaTable("Player")

function plyMeta:GetMoney()
    return self:GetNW2Int("ArtoRP_Money", 0)
end

function plyMeta:CanAfford(amount)
    return self:GetMoney() >= amount
end

function plyMeta:FormatMoney()
    return "$" .. string.Comma(self:GetMoney())
end

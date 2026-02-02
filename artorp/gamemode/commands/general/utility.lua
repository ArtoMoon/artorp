--[[
    General Commands
]]

ArtoRP.RegisterCommand("ping", function(ply, args)
    ply:ChatPrint("Pong! " .. (ply:Ping()) .. "ms")
end, "Check your ping")

ArtoRP.RegisterCommand("money", function(ply, args)
    ply:ChatPrint("You have: " .. ply:FormatMoney())
end, "Check your wallet")

ArtoRP.RegisterCommand("setmoney", function(ply, args)
    if not ply:IsSuperAdmin() then return end
    local amount = tonumber(args[1]) or 0
    ply:SetMoney(amount)
    ply:ChatPrint("Set money to " .. amount)
end, "Set money (Admin)")

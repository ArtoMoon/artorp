--[[
    ArtoRP - Main Configuration
    Edit this file to configure your server.
]]

ArtoRP.Config = ArtoRP.Config or {}

--[[
    SERVER SAHIPLERI & ADMINLER
    SteamID'nizi https://steamid.io adresinden bulabilirsiniz.
    Format: ["STEAM_0:0:12345678"] = "superadmin",
]]
ArtoRP.Config.Admins = {
    ["STEAM_0:0:12345678"] = "superadmin", -- Örnek (Kendi SteamID'nizi buraya yazin)
    ["STEAM_0:1:50402246"] = "superadmin", -- Arto (Tahmini, degistirebilirsiniz)
}

--[[
    VIP OYUNCULAR
    Format: ["STEAM_0:0:12345678"] = true,
]]
ArtoRP.Config.VIPs = {
    ["STEAM_0:0:12345678"] = true,
}

--[[
    MARKET (F4 MENU)
    Parayla satin alinabilecek esyalar.
]]
ArtoRP.Config.Entities = {
    {
        name = "Money Printer",
        ent = "arto_printer",
        price = 1000,
        desc = "Prints money over time.",
        model = "models/props_c17/consolebox01a.mdl" -- Icon for UI
    },
    {
        name = "Kazma",
        ent = "arto_pickaxe",
        price = 250,
        desc = "Tas ve maden kirmak icin.",
        model = "models/pickaxe.mdl"
    },
    -- Ileride baska seyler de eklenebilir (Silah Shipment vb.)
}

ArtoRP.Log("Config Loaded.")

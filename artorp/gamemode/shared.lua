--[[
    ArtoRP - Shared Entry Point
    Initializing the Global 'Client' object
]]

GM.Name = "ArtoRP"
GM.Author = "Arto"
GM.Email = "N/A"
GM.Website = "N/A"

ArtoRP = ArtoRP or {}
ArtoRP.Version = "1.0.0"
ArtoRP.Modules = {}

-- Utility to print colored logs
function ArtoRP.Log(msg)
    MsgC(Color(0, 255, 255), "[ArtoRP] ", Color(255, 255, 255), msg .. "\n")
end

-- Shared Notification Helper
function ArtoRP.Notify(ply, msgType, duration, message)
    if SERVER then
        if IsValid(ply) then 
            ply:ChatPrint("[ArtoRP] " .. message)
            -- You can add net messages here for UI notifications later
        end
    else
        chat.AddText(Color(255, 140, 0), "[ArtoRP] ", Color(255, 255, 255), message)
    end
end

-- Load Configuration EARLY (Before Modules)
if SERVER then AddCSLuaFile("sh_config.lua") end
include("sh_config.lua")

-- Helper to make sure Config table exists
ArtoRP.Config = ArtoRP.Config or {}

-- Load the Core Loader
ArtoRP.Log("Initializing ArtoRP...")

-- Derive from sandbox
DeriveGamemode("sandbox")

-- Module Loader (moved from core/sh_loader.lua to fix path issues)
ArtoRP.Loader = {}

local function LoadFile(relativePath)
    local fileName = string.GetFileFromFilename(relativePath)
    
    if string.StartWith(fileName, "sh_") then
        if SERVER then 
            AddCSLuaFile(relativePath)
        end
        include(relativePath)
        ArtoRP.Log("Loaded SHARED module: " .. fileName)
    elseif string.StartWith(fileName, "sv_") then
        if SERVER then
            include(relativePath)
            ArtoRP.Log("Loaded SERVER module: " .. fileName)
        end
    elseif string.StartWith(fileName, "cl_") then
        if SERVER then
            AddCSLuaFile(relativePath)
        else
            include(relativePath)
            ArtoRP.Log("Loaded CLIENT module: " .. fileName)
        end
    end
end

function ArtoRP.Loader.LoadModules()
    local files, folders = file.Find("gamemodes/artorp/gamemode/modules/*", "GAME")
    
    -- Load files in root modules folder
    for _, v in ipairs(files) do
        LoadFile("modules/" .. v)
    end
    
    -- Load files in subfolders (recursive 1 level deep for now, can be expanded)
    for _, folder in ipairs(folders) do
        local subFiles, _ = file.Find("gamemodes/artorp/gamemode/modules/" .. folder .. "/*", "GAME")
        for _, v in ipairs(subFiles) do
            LoadFile("modules/" .. folder .. "/" .. v)
        end
    end
end

-- Start Loading
ArtoRP.Loader.LoadModules()

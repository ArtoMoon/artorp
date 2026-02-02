--[[
    Command Handler module
]]

ArtoRP.Commands = ArtoRP.Commands or {}

function ArtoRP.RegisterCommand(cmd, callback, help)
    ArtoRP.Commands[cmd] = {
        action = callback,
        help = help or "No description"
    }
    ArtoRP.Log("Registered Command: /" .. cmd)
end

hook.Add("PlayerSay", "ArtoRP.Commands.Parse", function(ply, text)
    if not string.StartWith(text, "/") then return end
    
    local args = string.Explode(" ", text)
    local cmd = string.lower(string.sub(table.remove(args, 1), 2)) -- remove / and get command
    
    if ArtoRP.Commands[cmd] then
        ArtoRP.Commands[cmd].action(ply, args)
        return ""
    end
end)

-- Load commands from gamemode/commands/
local function LoadCommands()
    local files, folders = file.Find("gamemodes/artorp/gamemode/commands/*", "GAME")
    
    for _, folder in ipairs(folders) do
        local subFiles = file.Find("gamemodes/artorp/gamemode/commands/" .. folder .. "/*.lua", "GAME")
        for _, v in ipairs(subFiles) do
            -- Use ../../ to go up from modules/chat/ to gamemode/, then into commands/
            include("../../commands/" .. folder .. "/" .. v)
            ArtoRP.Log("Loaded Command File: " .. v)
        end
    end
end

LoadCommands()

--[[
    ArtoRP - Client Entry Point
]]

include("shared.lua")
include("sh_config.lua")

-- Manually load shared modules on client (auto-loader doesn't work for client)
include("modules/jobs/sh_jobs.lua")
include("modules/economy/sh_money.lua")

-- Manually load client modules
include("modules/ui/cl_jobmenu.lua")
include("modules/ui/cl_hud.lua")
include("modules/ui/cl_chat.lua")
include("modules/ui/cl_wepswitch.lua")
include("modules/ui/cl_pickup.lua")
include("modules/ui/cl_scoreboard.lua")
include("modules/ui/cl_notifications.lua")
include("modules/ui/sh_broadcast.lua")
include("modules/ui/sh_admin.lua")
include("modules/ui/cl_thirdperson.lua")
include("modules/ui/cl_keys.lua")

-- Client-side initialization
function GM:Initialize()
    MsgC(Color(0, 255, 255), "[ArtoRP] ", Color(255, 255, 255), "Client Init Complete.\n")
    
    -- Print loaded jobs for debugging
    timer.Simple(1, function()
        if ArtoRP.JobsByIndex then
            MsgC(Color(0, 255, 255), "[ArtoRP] ", Color(255, 255, 255), "Jobs available: " .. table.Count(ArtoRP.JobsByIndex) .. "\n")
            for i, job in pairs(ArtoRP.JobsByIndex) do
                MsgC(Color(0, 255, 255), "[ArtoRP] ", Color(255, 255, 255), "  - " .. job.name .. "\n")
            end
        else
            MsgC(Color(255, 0, 0), "[ArtoRP] ", Color(255, 255, 255), "ERROR: JobsByIndex is nil!\n")
        end
    end)
end

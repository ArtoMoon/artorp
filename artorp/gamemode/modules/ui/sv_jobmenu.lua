--[[
    UI Module - Server Side
    Handle job change requests
]]

-- Console command for job changes
concommand.Add("artorp_changejob", function(ply, cmd, args)
    local jobIndex = tonumber(args[1])
    
    if not jobIndex then
        ply:ChatPrint("Invalid job index!")
        return
    end
    
    ply:ChangeJob(jobIndex)
end)

ArtoRP.Log("UI Server Module loaded")

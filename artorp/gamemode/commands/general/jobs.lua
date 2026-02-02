--[[
    Job Commands
]]

ArtoRP.RegisterCommand("job", function(ply, args)
    local jobName = table.concat(args, " ")
    
    -- Find job by name
    for index, data in pairs(ArtoRP.JobsByIndex) do
        if string.lower(data.name) == string.lower(jobName) then
            ply:ChangeJob(index)
            return
        end
    end
    
    ply:ChatPrint("Job not found!")
end, "Change your job")

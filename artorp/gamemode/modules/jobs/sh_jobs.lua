
ArtoRP.Jobs = {}
ArtoRP.JobsByIndex = {}
ArtoRP.JobCount = 0

function ArtoRP.RegisterJob(name, data)
    ArtoRP.JobCount = ArtoRP.JobCount + 1
    local index = ArtoRP.JobCount
    
    local jobData = data
    jobData.name = name
    jobData.index = index
    
    ArtoRP.Jobs[name] = jobData
    ArtoRP.JobsByIndex[index] = jobData
    
    -- Register as a Team
    team.SetUp(index, name, data.color or Color(255, 255, 255))
    
    if SERVER then
        ArtoRP.Log("Registered Job: " .. name)
    end
    return index
end

-- Default Jobs
TEAM_CITIZEN = ArtoRP.RegisterJob("Citizen", {
    color = Color(20, 150, 20),
    model = "models/player/Group01/male_07.mdl",
    description = "A regular citizen.",
    salary = 45,
    max = 0 -- Infinite
})

TEAM_POLICE = ArtoRP.RegisterJob("Police Officer", {
    color = Color(25, 25, 170),
    model = "models/player/police.mdl",
    description = "Protect the city.",
    salary = 65,
    max = 4,
    weapons = {"weapon_pistol"}
})

TEAM_MEDIC = ArtoRP.RegisterJob("Medic", {
    color = Color(255, 50, 50),
    model = "models/player/kleiner.mdl",
    description = "Heal injured players.",
    salary = 55,
    max = 3,
    weapons = {"weapon_medkit"}
})

TEAM_GUNDEALER = ArtoRP.RegisterJob("Gun Dealer", {
    color = Color(255, 140, 0),
    model = "models/player/monk.mdl",
    description = "Sell weapons to players.",
    salary = 50,
    max = 2
})

TEAM_GANGSTER = ArtoRP.RegisterJob("Gangster", {
    color = Color(75, 75, 75),
    model = "models/player/Group03/male_07.mdl",
    description = "Break the law and cause chaos.",
    salary = 40,
    max = 6,
    weapons = {"weapon_pistol"}
})

TEAM_MAYOR = ArtoRP.RegisterJob("Mayor", {
    color = Color(255, 215, 0),
    model = "models/player/breen.mdl",
    description = "Lead the city and make laws.",
    salary = 100,
    max = 1
})

TEAM_VIP_THIEF = ArtoRP.RegisterJob("VIP Thief", {
    color = Color(100, 0, 100),
    model = "models/player/phoenix.mdl",
    description = "Professional thief. VIP Only.",
    salary = 80,
    max = 4,
    weapons = {"weapon_crowbar", "weapon_pistol"},
    vip = true
})

-- Player meta
local plyMeta = FindMetaTable("Player")

function plyMeta:GetJobData()
    return ArtoRP.JobsByIndex[self:Team()]
end

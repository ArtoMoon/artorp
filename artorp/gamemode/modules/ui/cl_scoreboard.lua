--[[
    UI Module - Scoreboard (HTML/CSS Modern Version)
    Matches ArtoRP Dark Glass Aesthetic
    - Fixed Avatar Loading using XML Fetch
]]

if SERVER then return end

-- Configuration
local config = {
    padding = 100, -- Padding from screen edges
}

-- Variables
local scoreboardPanel = nil
ArtoRP = ArtoRP or {}
ArtoRP.AvatarCache = ArtoRP.AvatarCache or {} -- Cache avatar URLs: [steamid64] = url

-- HTML Source
local htmlSource = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@500;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            margin: 0; padding: 0;
            width: 100vw; height: 100vh;
            overflow: hidden;
            font-family: 'Rajdhani', sans-serif;
            display: flex;
            justify-content: center;
            align-items: flex-start;
            padding-top: 100px;
        }

        #container {
            width: 70%;
            max-width: 1000px;
            background: rgba(10, 10, 14, 0.9);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-top: 4px solid #FF8c00;
            border-radius: 4px;
            box-shadow: 0 20px 50px rgba(0,0,0,0.5);
            display: flex;
            flex-direction: column;
            animation: fadeIn 0.3s ease;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .header {
            padding: 20px 30px;
            background: linear-gradient(90deg, rgba(255,140,0,0.1), transparent);
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid rgba(255,255,255,0.05);
        }

        .title {
            font-size: 32px;
            font-weight: 700;
            color: #fff;
            letter-spacing: 2px;
            text-transform: uppercase;
        }

        .server-info {
            font-size: 18px;
            color: #888;
            font-weight: 500;
        }

        #player-list {
            padding: 20px;
            max-height: 60vh;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        /* Scrollbar */
        #player-list::-webkit-scrollbar { width: 6px; }
        #player-list::-webkit-scrollbar-track { background: rgba(0,0,0,0.2); }
        #player-list::-webkit-scrollbar-thumb { background: #FF8c00; border-radius: 3px; }

        .player-card {
            background: rgba(255, 255, 255, 0.03);
            border-left: 3px solid transparent;
            padding: 12px 20px;
            display: flex;
            align-items: center;
            transition: all 0.2s;
        }

        .player-card:hover {
            background: rgba(255, 255, 255, 0.06);
            transform: translateX(5px);
        }

        .p-avatar {
            width: 40px; height: 40px;
            background: #333;
            border-radius: 4px;
            margin-right: 20px;
            background-size: cover;
            border: 1px solid rgba(255,255,255,0.1);
        }

        .p-info {
            flex: 1;
            display: flex;
            flex-direction: column;
        }

        .p-name {
            font-size: 20px;
            font-weight: 600;
            color: #eee;
        }

        .p-job {
            font-size: 14px;
            color: #aaa;
            text-transform: uppercase;
            font-weight: 600;
        }

        .p-meta {
            display: flex;
            gap: 30px;
            color: #888;
            font-weight: 600;
            font-size: 16px;
        }

        .p-rank {
            font-size: 11px;
            font-weight: 800;
            text-transform: uppercase;
            padding: 4px 10px;
            border-radius: 4px;
            color: white;
            background: #444;
            margin-left: 20px; /* Increased from 15px */
            letter-spacing: 1px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
            display: inline-block; /* Ensure margins work well */
            vertical-align: middle;
        }
        
        /* Add spacing if we have multiple badges */
        .p-rank + .p-rank {
            margin-left: 10px;
        }
        
        .rank-superadmin { background: #ff4444; box-shadow: 0 0 10px rgba(255, 68, 68, 0.4); } 
        .rank-admin { background: #ffbb33; color: black; box-shadow: 0 0 10px rgba(255, 187, 51, 0.4); }
        
        /* Special VIP Design */
        .rank-vip { 
            background: linear-gradient(135deg, #ad33ff, #8000ff);
            box-shadow: 0 0 15px rgba(173, 51, 255, 0.6);
            border: 1px solid rgba(255,255,255,0.2);
            text-shadow: 0 0 2px black;
        }
        
        .rank-user { display: none; }

    </style>
</head>
<body>
    <div id="container">
        <div class="header">
            <div class="title">Arto Roleplay</div>
            <div class="server-info" id="server-stats">Players: 0/0</div>
        </div>
        <div id="player-list">
            <!-- JS Populates -->
        </div>
    </div>

    <script>
        function updateBoard(serverName, playerCount, maxPlayers, playersMsg) {
            document.querySelector('.title').innerText = serverName;
            document.getElementById('server-stats').innerText = `PLAYERS: ${playerCount} / ${maxPlayers}`;
            
            const list = document.getElementById('player-list');
            const players = JSON.parse(playersMsg);
            
            let html = '';
            
            players.sort((a,b) => a.job.localeCompare(b.job)); 
            
            players.forEach(p => {
                let pingClass = 'ping-good';
                if(p.ping > 100) pingClass = 'ping-med';
                if(p.ping > 200) pingClass = 'ping-high';

                // Avatar
                const avatarUrl = p.avatarUrl || 'https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/fe/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg';
                
                // Rank formatting
                let rankHtml = '';
                
                // 1. Regular Rank
                if(p.rank === 'superadmin') { 
                    rankHtml += '<span class="p-rank rank-superadmin">OWNER</span>'; 
                } else if(p.rank === 'admin') { 
                    rankHtml += '<span class="p-rank rank-admin">ADMIN</span>'; 
                }
                
                // 2. VIP Badge (Independent)
                if(p.isVIP) {
                    rankHtml += '<span class="p-rank rank-vip">VIP</span>';
                }
                
                html += `
                <div class="player-card" style="border-left-color: ${p.teamColor}">
                    <img src="${avatarUrl}" class="p-avatar">
                    <div class="p-info">
                        <div class="p-name">
                            ${p.name}
                            ${rankHtml}
                        </div>
                        <div class="p-job" style="color: ${p.teamColor}">${p.job}</div>
                    </div>
                    <div class="p-meta">
                        <div class="${pingClass}">${p.ping}ms</div>
                    </div>
                </div>
                `;
            });
            
            list.innerHTML = html;
        }
    </script>
</body>
</html>
]]

local function CreateScoreboard()
    if IsValid(scoreboardPanel) then scoreboardPanel:Remove() end
    
    scoreboardPanel = vgui.Create("DHTML")
    scoreboardPanel:SetSize(ScrW(), ScrH())
    scoreboardPanel:SetPos(0, 0)
    scoreboardPanel:SetHTML(htmlSource)
    scoreboardPanel:SetVisible(false)
end

-- Helper: Fetch Avatar URL via XML
local function FetchAvatar(sid64)
    if not sid64 or sid64 == "" or sid64 == "0" then return end
    if ArtoRP.AvatarCache[sid64] then return end -- Already fetching or fetched
    
    ArtoRP.AvatarCache[sid64] = "pending" -- prevent double fetch
    
    local url = "https://steamcommunity.com/profiles/" .. sid64 .. "?xml=1"
    http.Fetch(url,
        function(body)
            -- Simple pattern match for <avatarFull>
            -- <avatarFull><![CDATA[URL]]></avatarFull>
            local _, _, avUrl = string.find(body, "<avatarFull><!%[CDATA%[(.-)%]%]></avatarFull>")
            
            if avUrl then
                ArtoRP.AvatarCache[sid64] = avUrl
            else
                -- Fallback pattern if no CDATA
                local _, _, avUrl2 = string.find(body, "<avatarFull>(.-)</avatarFull>")
                if avUrl2 then
                    ArtoRP.AvatarCache[sid64] = avUrl2
                end
            end
        end,
        function(err)
            -- fail silently
        end
    )
end

local function UpdateScoreboard()
    if not IsValid(scoreboardPanel) then return end
    
    local players = {}
    for _, ply in ipairs(player.GetAll()) do
        local col = team.GetColor(ply:Team())
        local colStr = string.format("rgb(%d,%d,%d)", col.r, col.g, col.b)
        local sid64 = ply:SteamID64() or "0"
        
        -- Trigger fetch if not cached
        if sid64 ~= "0" and not ArtoRP.AvatarCache[sid64] then
            FetchAvatar(sid64)
        end
        
        -- Get cached URL (ignore 'pending')
        local avUrl = ArtoRP.AvatarCache[sid64]
        if avUrl == "pending" then avUrl = nil end
        
        table.insert(players, {
            name = string.gsub(ply:Nick(), "'", "\\'"),
            job = team.GetName(ply:Team()),
            ping = ply:Ping(),
            teamColor = colStr,
            steamid = sid64,
            avatarUrl = avUrl,
            rank = ply:GetUserGroup(),
            isVIP = ply:GetNW2Bool("ArtoRP_IsVIP", false)
        })
    end
    
    local json = util.TableToJSON(players)
    -- Escape backslashes for JS string
    json = string.gsub(json, "\\", "\\\\") 
    json = string.gsub(json, "'", "\\'")
    
    local hostname = string.gsub(GetHostName(), "'", "\\'")
    local js = string.format("updateBoard('%s', %d, %d, '%s')", 
        hostname, #players, game.MaxPlayers(), json)
        
    scoreboardPanel:RunJavascript(js)
end

-- Hooks
hook.Add("ScoreboardShow", "ArtoRP.Scoreboard.Show", function()
    if not IsValid(scoreboardPanel) then CreateScoreboard() end
    
    scoreboardPanel:SetVisible(true)
    scoreboardPanel:MakePopup()
    scoreboardPanel:SetKeyboardInputEnabled(false) 
    
    UpdateScoreboard()
    
    -- Keep updating to catch avatars loading in
    timer.Create("ArtoRP.Scoreboard.Updater", 1, 0, function()
        if IsValid(scoreboardPanel) and scoreboardPanel:IsVisible() then
            UpdateScoreboard()
        else
            timer.Remove("ArtoRP.Scoreboard.Updater")
        end
    end)
    
    return true
end)

hook.Add("ScoreboardHide", "ArtoRP.Scoreboard.Hide", function()
    if IsValid(scoreboardPanel) then
        scoreboardPanel:SetVisible(false)
    end
    timer.Remove("ArtoRP.Scoreboard.Updater")
end)

-- Init
hook.Add("InitPostEntity", "ArtoRP.Scoreboard.Init", function()
    CreateScoreboard()
end)

CreateScoreboard()

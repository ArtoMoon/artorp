--[[
    UI Module - Admin Panel (F5)
    Dashboard style admin interface.
]]

if SERVER then
    util.AddNetworkString("ArtoRP.Admin.Action")
    util.AddNetworkString("ArtoRP.Admin.RequestWarnings")
    util.AddNetworkString("ArtoRP.Admin.SendWarnings")
    
    ArtoRP.WarningLog = ArtoRP.WarningLog or {}
    
    -- Send Warnings to Client
    net.Receive("ArtoRP.Admin.RequestWarnings", function(len, ply)
        if not (ply:IsAdmin() or ply:IsSuperAdmin() or ply:GetUserGroup() == "mod") then return end
        
        net.Start("ArtoRP.Admin.SendWarnings")
        net.WriteTable(ArtoRP.WarningLog)
        net.Send(ply)
    end)
    
    net.Receive("ArtoRP.Admin.Action", function(len, ply)
        local rank = ply:GetUserGroup()
        if not (ply:IsAdmin() or ply:IsSuperAdmin() or rank == "mod") then return end
        
        local action = net.ReadString()
        local target = net.ReadEntity()
        local data = net.ReadString()
        
        if not IsValid(target) and action ~= "announce" then return end
        
        -- MOD RESTRICTIONS
        if rank == "mod" then
            local allowed = { ["goto"]=true, ["bring"]=true, ["warn"]=true, ["slay"]=true }
            if not allowed[action] then
                ply:ChatPrint("[ArtoRP] Mods can only Goto, Bring, Warn or Slay!")
                return
            end
        end
        
        if action == "slay" then
            target:Kill()
            ply:ChatPrint("[ArtoRP] Slayed " .. target:Nick())
        elseif action == "kick" then
            target:Kick(data or "Kicked by Admin")
        elseif action == "bring" then
            target:SetPos(ply:GetPos() + Vector(0,0,10))
            ply:ChatPrint("[ArtoRP] brought " .. target:Nick())
        elseif action == "goto" then
            ply:SetPos(target:GetPos() + Vector(0,0,10))
        elseif action == "warn" then
            local reason = (data and data ~= "") and data or "No Reason Given"
            
            -- Use new Global API (saves to DB)
            ArtoRP.AddWarning(target, ply:Nick(), reason)
            
            -- Add to Dashboard Log
            table.insert(ArtoRP.WarningLog, 1, {
                target = target:Nick(),
                admin = ply:Nick(),
                reason = reason,
                time = os.date("%H:%M")
            })
            if #ArtoRP.WarningLog > 50 then table.remove(ArtoRP.WarningLog) end
            
            target:ChatPrint("[WARNING] You have been warned by Staff!")
            target:ChatPrint("Reason: " .. reason)
            
            ply:ChatPrint("[ArtoRP] Warned " .. target:Nick() .. " for: " .. reason)
        elseif action == "announce" then
            net.Start("ArtoRP.Broadcast")
            net.WriteString(data)
            net.WriteString(ply:Nick())
            net.Broadcast()
        elseif action == "rank" then
            RunConsoleCommand("artorp_setrank", target:Nick(), data)
            ply:ChatPrint("[ArtoRP] Updated rank for " .. target:Nick())
        elseif action == "setvip" then
            RunConsoleCommand("artorp_setvip", target:Nick(), data)
            ply:ChatPrint("[ArtoRP] Updated VIP status for " .. target:Nick())
        elseif action == "setmoney" then
            -- STRICT SUPERADMIN CHECK
            if not ply:IsSuperAdmin() then
                ply:ChatPrint("[ArtoRP] ACCESS DENIED: Only SuperAdmins can set money.")
                return 
            end
            
            local amount = tonumber(data) or 0
            if target.SetMoney then
                target:SetMoney(amount)
                ply:ChatPrint("[ArtoRP] Set money of " .. target:Nick() .. " to $" .. amount)
                target:ChatPrint("[ArtoRP] Your money has been set to $" .. amount .. " by " .. ply:Nick())
            end
        end
    end)
    return
end

-- Client Logic
local adminPanel = nil

-- Receive Warnings from Server (Dashboard)
net.Receive("ArtoRP.Admin.SendWarnings", function()
    local logs = net.ReadTable()
    if IsValid(adminPanel) then
        local json = util.TableToJSON(logs)
        adminPanel:RunJavascript("populateWarnings('" .. json .. "')")
    end
end)

-- Receive My Warnings (Personal UI)
net.Receive("ArtoRP.OpenWarnUI", function()
    local warns = net.ReadTable()
    
    if IsValid(ArtoRP_WarnPanel) then ArtoRP_WarnPanel:Remove() end
    
    ArtoRP_WarnPanel = vgui.Create("DHTML")
    ArtoRP_WarnPanel:SetSize(600, 500)
    ArtoRP_WarnPanel:Center()
    ArtoRP_WarnPanel:MakePopup()
    
    local html = [[
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@500;600;700&display=swap" rel="stylesheet">
        <style>
            body { 
                margin: 0; background: rgba(15, 15, 20, 0.98); 
                font-family: 'Rajdhani', sans-serif; 
                border: 1px solid rgba(255,255,255,0.1);
                border-top: 4px solid #FF8c00;
                overflow: hidden; display: flex; flex-direction: column;
            }
            .header { padding: 20px; text-align: center; border-bottom: 2px solid rgba(255, 140, 0, 0.2); background: rgba(255, 140, 0, 0.05); }
            .title { color: white; font-size: 28px; font-weight: 700; letter-spacing: 2px; text-transform: uppercase; }
            .subtitle { color: #888; font-size: 14px; margin-top: 5px; font-weight: 600; }
            
            .content { flex: 1; padding: 20px; overflow-y: auto; }
            
            .warn-card { 
                background: rgba(255, 255, 255, 0.03); 
                border-left: 3px solid #FF8c00;
                border-radius: 0 4px 4px 0;
                padding: 15px; margin-bottom: 10px;
                display: flex; justify-content: space-between; align-items: center;
                transition: 0.2s;
            }
            .warn-card:hover { background: rgba(255, 255, 255, 0.06); }
            
            .w-info { display: flex; flex-direction: column; }
            .w-reason { color: white; font-size: 18px; font-weight: 600; }
            .w-admin { color: #888; font-size: 13px; margin-top: 3px; }
            .w-admin span { color: #FF8c00; }
            .w-date { color: #666; font-size: 14px; font-weight: 700; background: rgba(0,0,0,0.3); padding: 5px 10px; border-radius: 4px; }
            
            .footer {
                padding: 0;
                background: rgba(0,0,0,0.2);
                border-top: 1px solid rgba(255,255,255,0.1);
            }
            
            .close-btn { 
                width: 100%;
                padding: 15px; background: transparent; 
                color: #888; border: none; font-family: inherit; font-weight: 700; 
                cursor: pointer; transition: 0.2s; 
                font-size: 14px; letter-spacing: 1px;
            }
            .close-btn:hover { background: #cc3333; color: white; }
            
            ::-webkit-scrollbar { width: 6px; }
            ::-webkit-scrollbar-track { background: rgba(0,0,0,0.2); }
            ::-webkit-scrollbar-thumb { background: #FF8c00; border-radius: 3px; }
        </style>
    </head>
    <body>
        <div class="header">
            <div class="title">Criminal Record</div>
            <div class="subtitle">WARNING LOGS</div>
        </div>
        
         <div class="content" id="list">
            <!-- Items go here -->
         </div>
         
         <div class="footer">
            <button class="close-btn" onclick="glua.close()">CLOSE WINDOW</button>
         </div>

         <script>
            function populate(json) {
                let data = [];
                try { data = JSON.parse(json); } catch(e) {}
                
                const list = document.getElementById('list');
                
                // Check if empty or null
                if(!data || data.length === 0) {
                     list.innerHTML = `
                        <div style="
                            display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%;
                            color: rgba(255,255,255,0.2); font-size: 24px; font-weight: 700; letter-spacing: 2px;
                        ">
                            NO CRIMINAL RECORD
                        </div>
                     `;
                     return;
                }
                
                // Show newest first
                data.reverse().forEach(w => {
                    const el = document.createElement('div');
                    el.className = 'warn-card';
                    el.innerHTML = `
                        <div class="w-info">
                            <div class="w-reason">${w.reason}</div>
                            <div class="w-admin">Sanctioned by <span>${w.admin}</span></div>
                        </div>
                        <div class="w-date">${w.time}</div>
                    `;
                    list.appendChild(el);
                });
            }
         </script>
    </body>
    </html>
    ]]
    
    ArtoRP_WarnPanel:SetHTML(html)
    ArtoRP_WarnPanel:AddFunction("glua", "close", function()
        if IsValid(ArtoRP_WarnPanel) then ArtoRP_WarnPanel:Remove() end
    end)
    
    -- Populate
    local json = util.TableToJSON(warns)
    timer.Simple(0.1, function()
        if IsValid(ArtoRP_WarnPanel) then
            ArtoRP_WarnPanel:RunJavascript("populate('" .. json .. "')")
        end
    end)
end)

local htmlSource = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@500;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --primary: #FF8c00; --bg: rgba(15, 15, 20, 0.98); --border: rgba(255,255,255,0.1); }
        body { margin: 0; font-family: 'Rajdhani', sans-serif; background: transparent; overflow: hidden; display: flex; justify-content: center; align-items: center; height: 100vh; }
        
        .window {
            width: 900px; height: 600px;
            background: var(--bg);
            border: 1px solid var(--border);
            border-top: 4px solid var(--primary);
            box-shadow: 0 30px 60px rgba(0,0,0,0.8);
            display: flex;
            border-radius: 4px;
        }
        
        /* Sidebar */
        .sidebar { width: 200px; background: rgba(0,0,0,0.3); border-right: 1px solid var(--border); padding: 20px 0; display: flex; flex-direction: column; }
        .brand { color: white; font-size: 24px; font-weight: 700; text-align: center; margin-bottom: 30px; letter-spacing: 2px; }
        .nav-btn { padding: 15px 30px; color: #888; cursor: pointer; transition: 0.2s; font-weight: 600; font-size: 18px; border-left: 3px solid transparent; }
        .nav-btn:hover, .nav-btn.active { background: rgba(255,140,0,0.1); color: white; border-left-color: var(--primary); }
        
        /* Main */
        .main { flex: 1; padding: 30px; display: flex; flex-direction: column; }
        .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .page-title { font-size: 28px; color: white; font-weight: 700; text-transform: uppercase; }
        
        /* Content Area for Pages */
        .page-content { flex: 1; display: none; overflow-y: auto; }
        .page-content.active { display: block; }
        
        /* Dashboard Stats */
        .stats-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin-bottom: 30px; }
        .stat-card { background: rgba(255,255,255,0.03); padding: 20px; border-radius: 4px; border: 1px solid var(--border); }
        .stat-val { font-size: 36px; color: white; font-weight: 700; }
        .stat-label { color: #888; font-size: 14px; text-transform: uppercase; font-weight: 600; }

        /* Warning Log List */
        .warn-list { 
            background: rgba(0,0,0,0.3); border: 1px solid var(--border); border-radius: 4px; 
            max-height: 200px; overflow-y: auto; display: flex; flex-direction: column;
        }
        .warn-row {
            display: grid; grid-template-columns: 1fr 1fr 2fr 0.5fr;
            padding: 8px 15px; border-bottom: 1px solid rgba(255,255,255,0.05);
            font-size: 14px; color: #ccc;
        }
        .warn-row:last-child { border-bottom: none; }
        .warn-header { font-weight: 700; color: #888; background: rgba(255,255,255,0.05); }
        .warn-target { color: var(--primary); font-weight: 600; }
        
        /* Player List */
        .player-list { display: flex; flex-direction: column; gap: 5px; }
        .p-row { background: rgba(255,255,255,0.02); padding: 10px 15px; display: flex; align-items: center; justify-content: space-between; border: 1px solid transparent; cursor: pointer; }
        .p-row:hover { background: rgba(255,255,255,0.05); border-color: var(--border); }
        .p-row.selected { background: rgba(255,140,0,0.1); border-color: var(--primary); }
        .p-name { color: white; font-weight: 600; font-size: 18px; }
        .p-job { color: #888; font-size: 14px; }
        
        /* Actions */
        .actions { margin-top: 20px; padding-top: 20px; border-top: 1px solid var(--border); display: flex; gap: 10px; }
        .btn { padding: 10px 20px; border: none; background: rgba(255,255,255,0.1); color: white; font-family: inherit; font-weight: 700; cursor: pointer; border-radius: 2px; transition: 0.2s; }
        .btn:hover { background: white; color: black; }
        .btn.danger { background: rgba(255,50,50,0.2); color: #ff5555; }
        .btn.danger:hover { background: #ff5555; color: white; }
        
        /* Announcement Input */
        .announce-box { display: flex; gap: 10px; margin-top: 20px; }
        input { flex: 1; background: rgba(0,0,0,0.3); border: 1px solid var(--border); padding: 10px; color: white; font-family: inherit; }
    </style>
</head>
<body>
    <div class="window">
        <div class="sidebar">
            <div class="brand">ADMIN</div>
            <div class="nav-btn active" onclick="showPage('dash', this)">DASHBOARD</div>
            <div class="nav-btn" onclick="showPage('players', this)">PLAYERS</div>
            <div class="nav-btn" onclick="glua.close()">CLOSE</div>
        </div>
        
        <div class="main">
            <!-- DASHBOARD -->
            <div id="dash" class="page-content active">
                <div class="header"><div class="page-title">Overview</div></div>
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-val" id="s-players">0</div>
                        <div class="stat-label">Online Players</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-val" id="s-uptime">0m</div>
                        <div class="stat-label">Uptime</div>
                    </div>
                </div>

                <div class="page-title" style="font-size: 20px; margin-bottom: 10px;">Recent Warnings</div>
                <div class="warn-list" id="w-list">
                    <div class="warn-row warn-header">
                        <div>TARGET</div> <div>ADMIN</div> <div>REASON</div> <div>TIME</div>
                    </div>
                    <!-- JS will populate rows here -->
                </div>
                
                <div style="margin-top: 30px;">
                    <div class="page-title" style="font-size: 20px; margin-bottom: 15px;">Quick Announcement</div>
                    <div class="announce-box">
                        <input type="text" id="announce-input" placeholder="Type message here...">
                        <button class="btn" onclick="sendAnnounce()">BROADCAST</button>
                    </div>
                </div>
            </div>
            
            <!-- PLAYERS -->
            <div id="players" class="page-content">
                <div class="header"><div class="page-title">Player Management</div></div>
                <div class="player-list" id="p-list"></div>
                <div id="selected-player-area" style="display:none; margin-top: 20px;">
                    <!-- VIP Management Panel -->
                    <div class="vip-panel" style="padding: 15px; background: rgba(173, 51, 255, 0.05); border: 1px solid rgba(173, 51, 255, 0.3); border-radius: 4px; margin-bottom: 20px;">
                        <div style="color: #ad33ff; font-weight: 700; margin-bottom: 10px; font-size: 14px; text-transform: uppercase;">Manage VIP Status</div>
                        <div style="display: flex; gap: 10px;">
                            <button class="btn" style="background: #ad33ff; color: white;" onclick="doAction('setvip', '1')">GIVE VIP</button>
                            <button class="btn" onclick="doAction('setvip', '0')">REMOVE VIP</button>
                        </div>
                    </div>

                    <!-- Money Management Panel (SuperAdmin Only visual hint, enforced by server) -->
                    <div class="money-panel" style="padding: 15px; background: rgba(0, 255, 100, 0.05); border: 1px solid rgba(0, 255, 100, 0.2); border-radius: 4px; margin-bottom: 20px;">
                        <div style="color: #00ff64; font-weight: 700; margin-bottom: 10px; font-size: 14px; text-transform: uppercase;">Manage Economy (SuperAdmin Only)</div>
                        <div style="display: flex; gap: 10px;">
                            <input type="number" id="money-input" placeholder="Amount..." style="width: 150px;">
                            <button class="btn" style="background: #00ff64; color: black;" onclick="doSetMoney()">SET MONEY</button>
                        </div>
                    </div>
                </div>
                
                <script>
                    function doSetMoney() {
                        const amt = document.getElementById('money-input').value;
                        if (!amt) return;
                        doAction('setmoney', amt);
                    }
                </script>

                <div class="actions">
                    <button class="btn" onclick="doAction('goto')">GOTO</button>
                    <button class="btn" onclick="doAction('bring')">BRING</button>
                    <button class="btn" onclick="doAction('slay')">SLAY</button>
                    <div style="width: 20px;"></div>
                    <button class="btn danger" onclick="doAction('kick')">KICK</button>
                </div>
                
                <!-- Warn Control Area -->
                <div style="margin-top: 15px; display: flex; align-items: center; gap: 10px; background: rgba(255, 187, 51, 0.05); padding: 10px; border: 1px solid rgba(255, 187, 51, 0.2); border-radius: 4px;">
                    <span style="color: #ffbb33; font-weight: 700;">WARN:</span>
                    <select id="warn-reason" style="flex: 1; background: rgba(0,0,0,0.5); border: 1px solid #ffbb33; color: white; padding: 8px; font-family: 'Rajdhani'; font-weight: 600;">
                        <option value="Rule Violation">General Rule Violation</option>
                        <option value="RDM">RDM (Random Deathmatch)</option>
                        <option value="VDM">VDM (Vehicle Deathmatch)</option>
                        <option value="FailRP">FailRP</option>
                        <option value="NLR">NLR (New Life Rule)</option>
                        <option value="Disrespect">Disrespect / Insult</option>
                        <option value="Mic Spam">Mic Spam</option>
                        <option value="Custom">Custom Reason...</option>
                    </select>
                    <button class="btn" style="background: #ffbb33; color: black; font-weight: 800;" onclick="doWarn()">SEND WARN</button>
                </div>

                <div class="actions">
                    <button class="btn" style="color: #ffbb33" onclick="doAction('rank', 'admin')">SET ADMIN</button>
                    <button class="btn" style="color: #33ccff" onclick="doAction('rank', 'mod')">SET MOD</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        let selectedPlayer = null;
    
        function showPage(id, btn) {
            document.querySelectorAll('.page-content').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));
            document.getElementById(id).classList.add('active');
            if(btn) btn.classList.add('active');
        }
        
        function updateStats(pCount, uptime) {
            document.getElementById('s-players').innerText = pCount;
            document.getElementById('s-uptime').innerText = uptime;
        }

        function populateWarnings(json) {
            const list = document.getElementById('w-list');
            // Keep header
            list.innerHTML = `
                <div class="warn-row warn-header">
                    <div>TARGET</div> <div>ADMIN</div> <div>REASON</div> <div>TIME</div>
                </div>
            `;
            const warns = JSON.parse(json);
            
            warns.forEach(w => {
                 const row = document.createElement('div');
                 row.className = 'warn-row';
                 row.innerHTML = `
                    <div class="warn-target">${w.target}</div>
                    <div>${w.admin}</div>
                    <div>${w.reason}</div>
                    <div>${w.time}</div>
                 `;
                 list.appendChild(row);
            });
        }
        
        function populatePlayers(json) {
            const list = document.getElementById('p-list');
            list.innerHTML = '';
            const players = JSON.parse(json);
            
            players.forEach(p => {
                const row = document.createElement('div');
                row.className = 'p-row';
                row.innerHTML = `<span class="p-name">${p.name}</span><span class="p-job">${p.job}</span>`;
                row.onclick = () => {
                    document.querySelectorAll('.p-row').forEach(r => r.classList.remove('selected'));
                    row.classList.add('selected');
                    selectedPlayer = p.id;
                    document.getElementById('selected-player-area').style.display = 'block';
                };
                list.appendChild(row);
            });
        }
        
        function doWarn() {
             if(!selectedPlayer) return;
             
             const sel = document.getElementById('warn-reason');
             let val = sel.value;
             
             if(val === 'Custom') {
                 val = prompt("Enter Custom Reason:", "Trolling");
                 if(!val) return;
             }
             
             glua.action('warn', selectedPlayer, val);
        }

        function doAction(act, data) {
            if(!selectedPlayer) return;
            glua.action(act, selectedPlayer, data || "");
        }
        
        function sendAnnounce() {
            const txt = document.getElementById('announce-input').value;
            if(!txt) return;
            glua.action("announce", 0, txt);
            document.getElementById('announce-input').value = "";
        }
    </script>
</body>
</html>
]]

local function OpenAdmin()
    local ply = LocalPlayer()
    local rank = ply:GetUserGroup()
    if not (ply:IsSuperAdmin() or ply:IsAdmin() or rank == "mod") then
        chat.AddText(Color(255, 50, 50), "[ArtoRP] You are not staff.")
        return 
    end

    if IsValid(adminPanel) then adminPanel:Remove() end
    
    adminPanel = vgui.Create("DHTML")
    adminPanel:SetSize(ScrW(), ScrH())
    adminPanel:SetPos(0, 0)
    adminPanel:SetHTML(htmlSource)
    adminPanel:MakePopup()
    
    -- Bridge
    adminPanel:AddFunction("glua", "close", function()
        adminPanel:Remove()
    end)
    
    adminPanel:AddFunction("glua", "action", function(act, targetID, data)
        -- Find player by UserID
        local target = nil
        if act ~= "announce" then
            for _, v in ipairs(player.GetAll()) do
                if v:UserID() == tonumber(targetID) then target = v break end
            end
            if not target then return end
        end

        net.Start("ArtoRP.Admin.Action")
        net.WriteString(act)
        net.WriteEntity(target or ply) -- if announce, target irrelevant
        net.WriteString(data)
        net.SendToServer()
    end)
    
    -- Request Data
    net.Start("ArtoRP.Admin.RequestWarnings")
    net.SendToServer()
    
    -- Populate Data
    timer.Simple(0.1, function()
        if not IsValid(adminPanel) then return end
        
        -- Stats
        local uptime = math.floor(CurTime() / 60) .. "m"
        adminPanel:RunJavascript(string.format("updateStats(%d, '%s')", #player.GetAll(), uptime))
        
        -- Players
        local list = {}
        for _, v in ipairs(player.GetAll()) do
            table.insert(list, {
                id = v:UserID(),
                name = string.gsub(v:Nick(), "'", ""),
                job = team.GetName(v:Team())
            })
        end
        local json = util.TableToJSON(list)
        adminPanel:RunJavascript("populatePlayers('" .. json .. "')")
    end)
end

hook.Add("PlayerButtonDown", "ArtoRP.Admin.F6", function(ply, key)
    if key == KEY_F6 and IsFirstTimePredicted() then
        OpenAdmin()
    end
end)

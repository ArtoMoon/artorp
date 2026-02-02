--[[
    UI Module - Client Side
    F4 Job Menu & Market & Inventory (HTML/CSS Modern Version)
]]

if SERVER then return end

-- HTML Source for the Menu
local menuHTML = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@500;600;700&family=Oswald:wght@300;500&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #FF8c00;
            --secondary: #e0e0e0;
            --bg-glass: rgba(15, 15, 20, 0.96);
            --border: rgba(255, 255, 255, 0.08);
            --card-hover: rgba(255, 140, 0, 0.1);
        }

        body {
            font-family: 'Rajdhani', sans-serif;
            background: transparent;
            margin: 0;
            width: 100vw;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            user-select: none;
            overflow: hidden;
        }

        .window {
            width: 1000px;
            height: 800px;
            background: var(--bg-glass);
            border: 1px solid var(--border);
            border-radius: 6px;
            box-shadow: 0 20px 50px rgba(0,0,0,0.8);
            display: flex;
            flex-direction: column;
            transform: scale(0.95);
            opacity: 0;
            transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }

        .window.open {
            transform: scale(1);
            opacity: 1;
        }

        .header {
            padding: 0;
            border-bottom: 1px solid var(--border);
            display: flex;
            flex-direction: column;
        }
        
        .header-top {
            padding: 20px 30px;
            display: flex; justify-content: space-between; align-items: center;
        }

        .title {
            font-size: 28px;
            font-weight: 700;
            color: white;
            text-transform: uppercase;
            letter-spacing: 1px;
            border-left: 4px solid var(--primary);
            padding-left: 15px;
        }
        
        .tabs {
            display: flex;
            padding: 0 30px;
            gap: 20px;
        }
        
        .tab-btn {
            background: transparent;
            border: none;
            color: #888;
            font-family: inherit;
            font-size: 18px;
            font-weight: 700;
            padding: 10px 15px;
            cursor: pointer;
            border-bottom: 3px solid transparent;
            transition: 0.2s;
        }
        
        .tab-btn:hover { color: white; }
        .tab-btn.active {
            color: white;
            border-bottom-color: var(--primary);
        }

        .close-hint { color: #666; font-size: 14px; font-weight: 600; }

        .page {
            display: none;
            flex: 1;
            padding: 20px;
            overflow-y: auto;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 15px;
            align-content: start;
        }
        
        .page.active { display: grid; }

        .page::-webkit-scrollbar { width: 6px; }
        .page::-webkit-scrollbar-track { background: transparent; }
        .page::-webkit-scrollbar-thumb { background: #333; border-radius: 3px; }

        .card {
            background: rgba(30,30,35,0.6);
            border: 1px solid var(--border);
            padding: 15px;
            border-radius: 4px;
            transition: all 0.2s ease;
            position: relative;
            cursor: pointer;
            display: flex;
            flex-direction: column;
            gap: 5px;
            min-height: 120px;
        }

        .card:hover {
            transform: translateY(-2px);
            background: rgba(40,40,45,0.9);
            border-color: var(--primary);
        }

        .card.current {
            border-color: #4eff8c;
            background: rgba(78, 255, 140, 0.05);
        }

        .card-header { display: flex; justify-content: space-between; align-items: center; }
        .card-name { font-size: 20px; font-weight: 700; color: white; text-transform: uppercase; }
        .card-price { font-size: 14px; color: #4eff8c; font-weight: 600; }
        .card-desc { font-size: 13px; color: #aaa; line-height: 1.4; flex: 1; margin-bottom: 15px; }

        .card-meta {
            display: flex;
            justify-content: flex-end;
            align-items: center;
            border-top: 1px solid rgba(255,255,255,0.05);
            padding-top: 10px;
            font-size: 12px;
            color: #666;
            font-weight: 700;
            gap: 5px;
        }

        .meta-btn {
            background: rgba(255,255,255,0.05);
            padding: 4px 10px;
            border-radius: 2px;
            color: #aaa;
            transition: 0.2s;
            cursor: pointer;
        }
        
        .meta-btn:hover { background: var(--primary); color: black; }
        .meta-btn.dang:hover { background: #ff4444; color: white; }

        .accent-bar {
            position: absolute;
            left: 0; top: 0; bottom: 0;
            width: 3px;
            background: #888;
        }

    </style>
</head>
<body>

    <div class="window" id="window">
        <!-- Header -->
        <div class="header">
            <div class="header-top">
                <div class="title">ArtoRP Menu</div>
                <div class="close-hint">PRESS F4 TO CLOSE</div>
            </div>
            
            <div class="tabs">
                <button class="tab-btn active" onclick="showTab('jobs')">JOBS</button>
                <button class="tab-btn" onclick="showTab('market')">MARKET</button>
                <button class="tab-btn" onclick="showTab('inventory')">INVENTORY</button>
            </div>
        </div>
        
        <!-- JOBS PAGE -->
        <div class="page active" id="page-jobs"></div>
        
        <!-- MARKET PAGE -->
        <div class="page" id="page-market"></div>
        
        <!-- INVENTORY PAGE -->
        <div class="page" id="page-inventory"></div>
    </div>

    <script>
        function setVisible(visible) {
            const win = document.getElementById('window');
            if (visible) win.classList.add('open');
            else win.classList.remove('open');
        }
        
        function showTab(id) {
            document.querySelectorAll('.page').forEach(el => el.classList.remove('active'));
            document.getElementById('page-' + id).classList.add('active');
            
            const btns = document.querySelectorAll('.tab-btn');
            btns.forEach(b => b.classList.remove('active'));
            if(id === 'jobs') btns[0].classList.add('active');
            if(id === 'market') btns[1].classList.add('active');
            if(id === 'inventory') btns[2].classList.add('active');
        }

        function clearContainer(id) {
            document.getElementById(id).innerHTML = '';
        }

        function addJob(index, name, desc, salary, count, max, r, g, b, isCurrent) {
            const div = document.createElement('div');
            div.className = 'card' + (isCurrent ? ' current' : '');
            div.onclick = function() { if (!isCurrent) glua.selectJob(index); };
            const colorStyle = `rgb(${r},${g},${b})`;
            div.innerHTML = `
                <div class="accent-bar" style="background: ${colorStyle}"></div>
                <div class="card-header"><span class="card-name">${name}</span><span class="card-price">$${salary}</span></div>
                <div class="card-desc">${desc}</div>
                <div class="card-meta">
                    <span style="margin-right:auto">PLAYERS: ${count} / ${max == 0 ? "∞" : max}</span>
                    <span class="meta-btn">${isCurrent ? 'CURRENT' : 'SELECT'}</span>
                </div>
            `;
            document.getElementById('page-jobs').appendChild(div);
        }
        
        function addEntity(index, name, desc, price) {
            const div = document.createElement('div');
            div.className = 'card';
            div.onclick = function() { glua.buyEntity(index); };
            div.innerHTML = `
                <div class="accent-bar" style="background: #4eff8c"></div>
                <div class="card-header"><span class="card-name">${name}</span><span class="card-price">$${price}</span></div>
                <div class="card-desc">${desc}</div>
                <div class="card-meta"><span class="meta-btn">PURCHASE</span></div>
            `;
            document.getElementById('page-market').appendChild(div);
        }
        
        function addInvItem(entIndex, name, money, sLvl, aLvl, heat, isOn, hasCooler, health, maxHealth) {
            const div = document.createElement('div');
            div.className = 'card';
            
            let heatColor = '#4eff8c';
            if(heat > 50) heatColor = '#ffbb33';
            if(heat > 80) heatColor = '#ff4444';
            
            let hpColor = '#4eff8c';
            if(health < 50) hpColor = '#ffbb33';
            if(health < 25) hpColor = '#ff4444';
            
            const powerText = isOn ? "RUNNING" : "STOPPED <span style='font-size:10px'>(Cooling)</span>";
            const powerBtnText = isOn ? "STOP" : "START";
            const coolerBtn = hasCooler ? "<span class='meta-btn' style='background:#4eff8c; color:black;'>COOLER EQUIPPED</span>" : `<span class="meta-btn" onclick="event.stopPropagation(); glua.invBuyCooler(${entIndex})">BUY COOLER ($2k)</span>`;

            div.innerHTML = `
                <div class="accent-bar" style="background: #00ddff"></div>
                <div class="card-header"><span class="card-name">${name}</span><span class="card-price">$${money}</span></div>
                <div class="card-desc">
                    <div>Speed: Lvl ${sLvl} | Amount: Lvl ${aLvl}</div>
                    <div style="margin-top:2px;">Health: <span style="color:${hpColor}; font-weight:700;">${health}/${maxHealth}</span></div>
                    <div style="margin-top:5px; font-weight:700; color:${heatColor}">HEAT: ${heat}% - ${powerText}</div>
                </div>
                <div class="card-meta" style="flex-wrap: wrap; gap: 5px;">
                    <span class="meta-btn" onclick="event.stopPropagation(); glua.invToggle(${entIndex})">${powerBtnText}</span>
                    ${coolerBtn}
                    <span class="meta-btn" onclick="event.stopPropagation(); glua.invUpSpeed(${entIndex})">SPD UP</span>
                    <span class="meta-btn" onclick="event.stopPropagation(); glua.invUpAmount(${entIndex})">AMT UP</span>
                    <span class="meta-btn" onclick="event.stopPropagation(); glua.invCollect(${entIndex})">COLLECT</span>
                    <span class="meta-btn dang" onclick="event.stopPropagation(); glua.invSell(${entIndex})">SELL</span>
                </div>
            `;
            document.getElementById('page-inventory').appendChild(div);
        }
        
        window.onload = function() {
            setTimeout(function() { if(window.glua) glua.ready(); }, 100);
        }
    </script>
</body>
</html>
]]

local jobHTMLPanel = nil

function ArtoRP.OpenJobMenu()
    if IsValid(jobHTMLPanel) then
        jobHTMLPanel:SetVisible(true)
        jobHTMLPanel:MakePopup()
        jobHTMLPanel:SetKeyboardInputEnabled(false) 
        jobHTMLPanel:Call("setVisible(true)")
        ArtoRP.RefreshJobData()
        ArtoRP.RefreshMarketData()
        ArtoRP.RefreshInventoryData()
        return
    end

    jobHTMLPanel = vgui.Create("DHTML")
    jobHTMLPanel:SetSize(ScrW(), ScrH())
    jobHTMLPanel:SetPos(0, 0)
    jobHTMLPanel:SetHTML(menuHTML)
    jobHTMLPanel:MakePopup()
    jobHTMLPanel:SetKeyboardInputEnabled(false)
    
    -- Bridge Lua -> JS
    jobHTMLPanel:AddFunction("glua", "selectJob", function(index)
        RunConsoleCommand("artorp_changejob", tostring(index))
        surface.PlaySound("buttons/button14.wav")
        ArtoRP.CloseJobMenu()
    end)
    
    jobHTMLPanel:AddFunction("glua", "buyEntity", function(index)
        net.Start("ArtoRP.Shop.BuyEntity")
        net.WriteInt(index, 32)
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
    end)
    
    -- Inventory Actions
    jobHTMLPanel:AddFunction("glua", "invUpSpeed", function(entIndex)
        local ent = Entity(entIndex)
        net.Start("ArtoRP.Inventory.UpgradeSpeed")
        net.WriteEntity(ent)
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
    end)

    jobHTMLPanel:AddFunction("glua", "invUpAmount", function(entIndex)
        local ent = Entity(entIndex)
        net.Start("ArtoRP.Inventory.UpgradeAmount")
        net.WriteEntity(ent)
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
    end)
    
    jobHTMLPanel:AddFunction("glua", "invBuyCooler", function(entIndex)
        local ent = Entity(entIndex)
        net.Start("ArtoRP.Inventory.BuyCooler")
        net.WriteEntity(ent)
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
    end)
    
    jobHTMLPanel:AddFunction("glua", "invToggle", function(entIndex)
        local ent = Entity(entIndex)
        net.Start("ArtoRP.Inventory.TogglePower")
        net.WriteEntity(ent)
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
    end)
    
    jobHTMLPanel:AddFunction("glua", "invCollect", function(entIndex)
        local ent = Entity(entIndex)
        net.Start("ArtoRP.Inventory.Collect")
        net.WriteEntity(ent)
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
    end)
    
    jobHTMLPanel:AddFunction("glua", "invSell", function(entIndex)
        local ent = Entity(entIndex)
        net.Start("ArtoRP.Inventory.Sell")
        net.WriteEntity(ent)
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
    end)
    
    jobHTMLPanel:AddFunction("glua", "ready", function()
        jobHTMLPanel:Call("setVisible(true)")
        ArtoRP.RefreshJobData()
        ArtoRP.RefreshMarketData()
        ArtoRP.RefreshInventoryData()
    end)
end

function ArtoRP.CloseJobMenu()
    if IsValid(jobHTMLPanel) then
        jobHTMLPanel:Call("setVisible(false)")
        timer.Simple(0.3, function()
            if IsValid(jobHTMLPanel) then 
                jobHTMLPanel:SetVisible(false) 
                gui.EnableScreenClicker(false) 
            end
        end)
    end
end

-- Refresh Functions for Jobs/Market Omitted (Unchanged)
function ArtoRP.RefreshJobData()
    if not IsValid(jobHTMLPanel) then return end
    jobHTMLPanel:Call("clearContainer('page-jobs')")
    for index, job in pairs(ArtoRP.JobsByIndex or {}) do
        local name = string.gsub(job.name, "'", "\\'")
        local desc = string.gsub(job.description or "No description", "'", "\\'")
        local col = job.color or Color(255,255,255)
        local isCurrent = (LocalPlayer():Team() == index)
        local js = string.format("addJob(%d, '%s', '%s', %d, %d, %d, %d, %d, %d, %s)",
            index, name, desc, job.salary, team.NumPlayers(index), job.max, col.r, col.g, col.b, tostring(isCurrent))
        jobHTMLPanel:RunJavascript(js)
    end
end

function ArtoRP.RefreshMarketData()
    if not IsValid(jobHTMLPanel) then return end
    jobHTMLPanel:Call("clearContainer('page-market')")
    if not ArtoRP.Config.Entities then return end
    for k, v in ipairs(ArtoRP.Config.Entities) do
        local name = string.gsub(v.name, "'", "\\'")
        local desc = string.gsub(v.desc, "'", "\\'")
        local js = string.format("addEntity(%d, '%s', '%s', %d)", k, name, desc, v.price)
        jobHTMLPanel:RunJavascript(js)
    end
end

function ArtoRP.RefreshInventoryData()
    if not IsValid(jobHTMLPanel) then return end
    jobHTMLPanel:Call("clearContainer('page-inventory')")
    
    -- Find owned printers
    for _, ent in ipairs(ents.FindByClass("arto_printer")) do
        -- Check ownership safely
        local isOwner = (ent.GetItemOwner and ent:GetItemOwner() == LocalPlayer())
        
        if isOwner then
            -- Found owned item
            local stored = ent:GetStoredMoney()
            local sLvl = ent:GetSpeedLevel()
            local aLvl = ent:GetAmountLevel()
            
            -- Heat System Data
            local heat = ent:GetHeat()
            local isOn = ent:GetIsOn()
            local hasCooler = ent:GetHasCooler()
            
            -- Health Data (Ensure valid numbers)
            local health = math.floor(ent:Health())
            local maxHealth = math.floor(ent:GetMaxHealth())
            if maxHealth == 0 then maxHealth = 100 end -- Fallback
            
            local js = string.format("addInvItem(%d, 'Money Printer', %d, %d, %d, %d, %s, %s, %d, %d)", 
                ent:EntIndex(), stored, sLvl, aLvl, heat, tostring(isOn), tostring(hasCooler), health, maxHealth)
            jobHTMLPanel:RunJavascript(js)
        end
    end
end

-- Refresh UI when server says so
net.Receive("ArtoRP.Inventory.Update", function()
    if IsValid(jobHTMLPanel) and jobHTMLPanel:IsVisible() then
        ArtoRP.RefreshInventoryData()
    end
end)

-- Auto Update Timer (Every 1 second while menu is open)
timer.Create("ArtoRP.UI.InventoryRefresh", 1, 0, function()
    if IsValid(jobHTMLPanel) and jobHTMLPanel:IsVisible() then
        ArtoRP.RefreshInventoryData()
    end
end)

-- Input Handling via PlayerButtonDown
hook.Add("PlayerButtonDown", "ArtoRP.UI.F4MenuToggle", function(ply, button)
    if button == KEY_F4 and IsFirstTimePredicted() then
        if IsValid(jobHTMLPanel) and jobHTMLPanel:IsVisible() then
            ArtoRP.CloseJobMenu()
        else
            ArtoRP.OpenJobMenu()
        end
    end
end)

-- Chat Command
hook.Add("OnPlayerChat", "ArtoRP.UI.F4Command", function(ply, text)
    if string.lower(text) == "!jobs" or string.lower(text) == "/jobs" then
        ArtoRP.OpenJobMenu()
        return true
    end
end)

MsgC(Color(0, 255, 255), "[ArtoRP] ", Color(255, 255, 255), "Modern HTML F4 Menu loaded.\n")

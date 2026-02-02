--[[
    UI Module - HUD (HTML/CSS Modern Version)
    Optimized for "Wow" Factor using DHTML
    - Money moved under Avatar
    - Layout Layout Refined
]]

if SERVER then return end

-- Remove any existing Lua HUD repaint hooks
hook.Remove("HUDPaint", "ArtoRP.HUD.Paint")

-- Hide default HUD
local hideHUD = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true,
    ["CHudDamageIndicator"] = false,
    ["CHudPoisonDamageIndicator"] = true,
    ["CHudSquadStatus"] = true,
}

hook.Add("HUDShouldDraw", "ArtoRP.HUD.HideDefault", function(name)
    if hideHUD[name] then return false end
end)

-- HTML Source Code
local hudHTML = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@500;700;800&family=Oswald:wght@300;400;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #FF8c00;
            --secondary: #e0e0e0;
            --danger: #ff2d2d;
            --dark-glass: rgba(10, 10, 14, 0.94);
            --border: rgba(255, 255, 255, 0.1);
        }
        
        body {
            margin: 0;
            padding: 0;
            overflow: hidden;
            width: 100vw;
            height: 100vh;
            font-family: 'Rajdhani', sans-serif;
            user-select: none;
        }

        .hidden { opacity: 0; transition: opacity 0.3s ease; }
        .visible { opacity: 1; }
        
        /* BOTTOM LEFT: PROFILE CARD */
        .profile-container {
            position: absolute;
            bottom: 40px;
            left: 40px;
            width: 420px;
            height: 160px; 
        }

        .profile-bg {
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: var(--dark-glass);
            border: 1px solid var(--border);
            border-radius: 6px;
            transform: skewX(-6deg);
            box-shadow: 0 10px 30px rgba(0,0,0,0.6);
            backdrop-filter: blur(4px);
            z-index: 0;
        }

        .profile-content {
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            z-index: 1;
            display: flex;
            align-items: flex-start; /* Changed to start so avatar stays at top */
            padding: 20px 25px; 
            gap: 20px;
        }

        /* Left Column: Avatar + Money */
        .left-col {
            display: flex;
            flex-direction: column;
            gap: 10px;
            align-items: center;
        }

        .avatar-placeholder {
            width: 90px;
            height: 90px;
            border: 1px solid rgba(255,255,255,0.15);
            flex-shrink: 0;
        }

        .money-display {
            font-size: 18px;
            color: #4eff8c;
            font-weight: 700;
            text-shadow: 0 0 5px rgba(78, 255, 140, 0.3);
            text-align: center;
        }

        .info-col {
            flex: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
            gap: 4px; 
            height: 100%;
        }

        .header-row {
            display: flex;
            justify-content: space-between;
            align-items: baseline;
            border-bottom: 1px solid rgba(255,255,255,0.05);
            padding-bottom: 2px; 
            margin-bottom: 2px;
        }

        .label { font-size: 11px; color: var(--primary); letter-spacing: 1px; font-weight: 700; }
        .role-label { font-size: 11px; color: #666; font-weight: 700; }

        .name-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 4px;
        }

        .player-name { font-size: 26px; color: white; font-weight: 800; text-transform: uppercase; line-height: 1; letter-spacing: 0.5px; }
        .role-name { font-size: 14px; color: #aaa; font-weight: 600; text-transform: uppercase; }

        /* Bars */
        .bars-container {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }

        .bar-wrap {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .bar-bg {
            flex: 1;
            height: 10px;
            background: rgba(30, 30, 35, 0.8);
            position: relative;
            border-radius: 1px;
        }
        .bar-fill {
            height: 100%;
            width: 50%;
            background: var(--primary);
            transition: width 0.3s ease-out;
            box-shadow: 0 0 8px rgba(255, 140, 0, 0.4);
        }
        
        .bar-fill.armor { background: var(--secondary); box-shadow: none; }
        .bar-val { font-size: 16px; font-weight: 700; color: #fff; width: 30px; text-align: right; }

        /* TOP RIGHT: WANTED */
        .wanted-box {
            position: absolute;
            top: 40px;
            right: 40px;
            width: 340px;
            padding: 20px;
        }
        
        .wanted-bg {
             position: absolute; top:0; left:0; right:0; bottom:0;
             background: linear-gradient(90deg, rgba(40,0,0,0.95), rgba(60,0,0,0.85));
             border: 1px solid rgba(255,50,50,0.3);
             border-right: 4px solid var(--danger);
             transform: skewX(-10deg);
             z-index: 0;
             box-shadow: 0 0 30px rgba(255,0,0,0.15);
             animation: pulse-border 2s infinite;
        }

        @keyframes pulse-border {
            0% { box-shadow: 0 0 20px rgba(255,0,0,0.1); border-color: rgba(255,50,50,0.3); }
            50% { box-shadow: 0 0 50px rgba(255,0,0,0.4); border-color: rgba(255,50,50,0.8); }
            100% { box-shadow: 0 0 20px rgba(255,0,0,0.1); border-color: rgba(255,50,50,0.3); }
        }
        
        .wanted-content {
            position: relative; z-index: 1;
            text-align: right;
            padding-right: 10px;
        }

        .wanted-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 5px;
        }
        .wanted-title { font-size: 36px; font-weight: 900; color: var(--danger); letter-spacing: 2px; text-transform: uppercase; }
        .wanted-timer { font-size: 20px; font-family: 'Oswald', sans-serif; color: white; }
        .wanted-reason { 
            background: rgba(100,0,0,0.4); 
            padding: 4px 12px; 
            font-size: 13px; 
            font-weight: 700;
            display: inline-block; 
            margin-top: 5px;
            border-left: 2px solid var(--danger);
        }

        /* AMMO */
        .ammo-box {
            position: absolute;
            bottom: 40px;
            right: 50px;
            text-align: right;
            color: white;
            text-shadow: 0 2px 10px rgba(0,0,0,0.8);
        }
        .ammo-main { display: flex; align-items: baseline; justify-content: flex-end; line-height: 0.8; }
        .clip { font-family: 'Oswald', sans-serif; font-size: 80px; font-weight: 400; letter-spacing: -3px; }
        .reserve { font-size: 32px; opacity: 0.6; margin-left: 12px; font-weight: 300; }
        .weapon-mode { font-size: 13px; letter-spacing: 3px; opacity: 0.8; margin-top: 8px; font-weight: 700; color: var(--primary); }

    </style>
</head>
<body>

    <!-- PROFILE -->
    <div class="profile-container">
        <div class="profile-bg"></div>
        <div class="profile-content">
            <!-- Left Col with Avatar and Money -->
            <div class="left-col">
                <div class="avatar-placeholder"></div>
                <div class="money-display">
                    <span id="money">$0</span>
                </div>
            </div>
            
            <div class="info-col">
                <div class="header-row">
                    <span class="label">IDENTITY</span>
                    <span class="role-label">ROLE</span>
                </div>
                
                <div class="name-row">
                    <span class="player-name" id="name">John Doe</span>
                    <span class="role-name" id="job">Citizen</span>
                </div>
                
                <div class="bars-container">
                    <div class="bar-wrap">
                        <div class="bar-bg"><div class="bar-fill" id="hp-bar" style="width: 100%"></div></div>
                        <span class="bar-val" id="hp-val">100</span>
                    </div>
                    <div class="bar-wrap">
                        <div class="bar-bg"><div class="bar-fill armor" id="ap-bar" style="width: 0%"></div></div>
                        <span class="bar-val" id="ap-val">0</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- WANTED -->
    <div class="wanted-box hidden" id="wanted-box">
        <div class="wanted-bg"></div>
        <div class="wanted-content">
            <div class="wanted-header">
                <span class="wanted-timer">02:00</span>
            </div>
            <div class="wanted-title">WANTED</div>
            <div class="wanted-reason">REASON: TRESPASSING</div>
        </div>
    </div>

    <!-- AMMO -->
    <div class="ammo-box hidden" id="ammo-box">
        <div class="ammo-main">
            <span class="clip" id="clip">30</span>
            <span class="reserve" id="reserve">/ 90</span>
        </div>
        <div class="weapon-mode">SEMI-AUTO</div>
    </div>

    <script>
        function updateStats(name, job, hp, maxHp, ap, money, isWanted) {
            document.getElementById('name').innerText = name;
            document.getElementById('job').innerText = job;
            document.getElementById('hp-bar').style.width = Math.min((hp/maxHp)*100, 100) + '%';
            document.getElementById('hp-val').innerText = Math.round(hp);
            document.getElementById('ap-bar').style.width = Math.min(ap, 100) + '%';
            document.getElementById('ap-val').innerText = Math.round(ap);
            document.getElementById('money').innerText = money;
            
            const wBox = document.getElementById('wanted-box');
            if (isWanted) {
                wBox.classList.remove('hidden');
                wBox.classList.add('visible');
            } else {
                wBox.classList.remove('visible');
                wBox.classList.add('hidden');
            }
        }
        
        function updateAmmo(visible, clip, reserve) {
            const aBox = document.getElementById('ammo-box');
            if (!visible) {
                 aBox.classList.remove('visible');
                 aBox.classList.add('hidden');
                 return;
            }
            aBox.classList.remove('hidden');
            aBox.classList.add('visible');
            document.getElementById('clip').innerText = clip;
            document.getElementById('reserve').innerText = '/ ' + reserve;
        }
    </script>
</body>
</html>
]]

-- Logic to recreate panel
if IsValid(ArtoRP_HUD_Panel) then ArtoRP_HUD_Panel:Remove() end
if IsValid(ArtoRP_HUD_Avatar_VGUI) then ArtoRP_HUD_Avatar_VGUI:Remove() end

local function CreateHUD()
    -- 1. Create HTML Panel
    ArtoRP_HUD_Panel = vgui.Create("DHTML")
    ArtoRP_HUD_Panel:SetPos(0, 0)
    ArtoRP_HUD_Panel:SetSize(ScrW(), ScrH())
    ArtoRP_HUD_Panel:SetHTML(hudHTML)
    ArtoRP_HUD_Panel:SetMouseInputEnabled(false)
    ArtoRP_HUD_Panel:SetKeyboardInputEnabled(false)
    ArtoRP_HUD_Panel:ParentToHUD()
    ArtoRP_HUD_Panel.Paint = function() end 
    
    -- 2. Create VGUI Avatar
    -- Recalculate positions based on CSS logic:
    -- Container: Left 40, Bottom 40. Height 160.
    -- Card Top Y = ScrH() - 40 - 160 = ScrH() - 200.
    -- Content Padding Top = 20.
    -- Avatar Y = (ScrH() - 200) + 20 = ScrH() - 180.
    -- Content Padding Left = 25.
    -- Avatar X = 40 + 25 = 65.
    
    local cardH = 160
    local cardX = 40
    local cardBottom = 40
    local cardTopY = ScrH() - cardBottom - cardH
    
    local padLeft, padTop = 25, 20
    
    local avX = cardX + padLeft
    local avY = cardTopY + padTop
    local avSize = 90
    
    ArtoRP_HUD_Avatar_VGUI = vgui.Create("AvatarImage")
    ArtoRP_HUD_Avatar_VGUI:SetSize(avSize, avSize)
    ArtoRP_HUD_Avatar_VGUI:SetPos(avX, avY)
    ArtoRP_HUD_Avatar_VGUI:SetPlayer(LocalPlayer(), 128)
    ArtoRP_HUD_Avatar_VGUI:ParentToHUD() 
    ArtoRP_HUD_Avatar_VGUI.currentPlayer = LocalPlayer()
end

-- Create immediately
CreateHUD()

-- Re-create on resolution change
hook.Add("OnScreenSizeChanged", "ArtoRP.HUD.Resized", function()
    CreateHUD()
end)

-- Update Hook
hook.Add("Think", "ArtoRP.HUD.UpdateHTML", function()
    if not IsValid(ArtoRP_HUD_Panel) then CreateHUD() return end
    
    -- Sync Avatar User
    if IsValid(ArtoRP_HUD_Avatar_VGUI) and ArtoRP_HUD_Avatar_VGUI.currentPlayer ~= LocalPlayer() then
        ArtoRP_HUD_Avatar_VGUI:SetPlayer(LocalPlayer(), 128)
        ArtoRP_HUD_Avatar_VGUI.currentPlayer = LocalPlayer()
    end

    local p = ArtoRP_HUD_Panel
    if CurTime() < (p.NextUpdate or 0) then return end
    p.NextUpdate = CurTime() + 0.1 
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local name = ply:Nick()
    local job = team.GetName(ply:Team())
    local hp = ply:Health()
    local maxHp = ply:GetMaxHealth()
    local ap = ply:Armor()
    local money = (ply.FormatMoney and ply:FormatMoney()) or string.Comma(ply:GetMoney())
    
    -- Ensure single currency symbol
    if not string.find(money, "[$€£]") then 
        money = "$" .. money 
    end
    
    local isWanted = ply:GetNWBool("ArtoRP_Wanted", false)
    
    -- Sanitize
    name = string.gsub(name, "'", "\\'")
    job = string.gsub(job, "'", "\\'")
    
    -- Safe JS Call wrapper
    local js = string.format("if(window.updateStats) updateStats('%s', '%s', %d, %d, %d, '%s', %s)", 
        name, job, hp, maxHp, ap, money, tostring(isWanted))
    p:RunJavascript(js)
    
    -- Ammo
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        local clip = wep:Clip1()
        local reserve = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
        if clip >= 0 then
            p:RunJavascript(string.format("if(window.updateAmmo) updateAmmo(true, %d, %d)", clip, reserve))
        else
            p:RunJavascript("if(window.updateAmmo) updateAmmo(false, 0, 0)")
        end
    else
        p:RunJavascript("if(window.updateAmmo) updateAmmo(false, 0, 0)")
    end
end)

MsgC(Color(0,255,100), "[ArtoRP] ", Color(255,255,255), "Modern HTML/CSS HUD Updated (v3).\n")

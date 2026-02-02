--[[
    UI Module - Chat System (HTML/CSS Modern Version)
    Matches the HUD/JobMenu Dark Glass Aesthetic
]]

if SERVER then return end

-- Configuration
-- Configuration
local chatConfig = {
    w = 500,
    h = 300,
    padding = 40,
    bottomOffset = 250, -- Above Profile HUD (160h + 40b + padding)
    hideDefault = true
}

-- helper to get dynamic pos
local function GetChatPos()
    local x = chatConfig.padding
    local y = ScrH() - chatConfig.h - chatConfig.bottomOffset
    return x, y
end

-- Hide Default Chat
if chatConfig.hideDefault then
    hook.Add("HUDShouldDraw", "ArtoRP.Chat.HideDefault", function(name)
        if name == "CHudChat" then return false end
    end)
end

-- Variables
local chatPanel = nil
local inputPanel = nil
local chatHTML = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #FF8c00;
            --bg-glass: rgba(10, 10, 14, 0.0);
            --bg-active: rgba(10, 10, 14, 0.85); 
        }
        
        body {
            margin: 0;
            padding: 10px;
            font-family: 'Rajdhani', sans-serif;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            justify-content: flex-end;
            height: 100vh;
            box-sizing: border-box;
            text-align: left;
        }
        
        #chat-log {
            display: flex;
            flex-direction: column;
            gap: 4px;
            width: 100%;
            height: 100%;
            overflow-y: hidden; 
            justify-content: flex-end;
            text-shadow: 1px 1px 2px rgba(0,0,0,0.8);
            align-items: flex-start;
        }

        .msg {
            background: linear-gradient(90deg, rgba(20,20,25,0.8), rgba(20,20,25,0));
            padding: 4px 10px;
            border-left: 3px solid #888;
            border-right: none;
            border-radius: 2px;
            color: #eee;
            font-size: 18px;
            animation: slideIn 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            transition: opacity 2s ease;
            max-width: 90%;
            display: flex;
            flex-direction: row;
            align-items: baseline;
            gap: 6px;
        }
        
        @keyframes slideIn {
            from { transform: translateX(-20px); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }

        /* Message Types */
        .msg.type-chat { border-color: var(--primary); }
        .msg.type-server { border-color: #4eff8c; background: linear-gradient(90deg, rgba(0,50,20,0.6), transparent); }
        .msg.type-error { border-color: #ff2d2d; }
        .msg.type-connect { border-color: #00aaff; }

        .sender {
            font-weight: 700;
            color: var(--primary);
            white-space: nowrap;
        }
        
        .content {
            font-weight: 500;
            word-wrap: break-word;
        }

        .msg.faded { opacity: 0; }
        
    </style>
</head>
<body>
    <div id="chat-log"></div>

    <script>
        const log = document.getElementById('chat-log');
        const MAX_MESSAGES = 50;
        
        function addMessage(type, sender, colorR, colorG, colorB, text) {
            const div = document.createElement('div');
            div.className = 'msg type-' + type;
            const nameColor = `rgb(${colorR},${colorG},${colorB})`;
            
            let html = '';
            if (sender) {
                html += `<span class="sender" style="color:${nameColor}">${sender}:</span>`;
            }
            html += `<span class="content">${text}</span>`;
            
            div.innerHTML = html;
            log.appendChild(div);
            
            if (log.children.length > MAX_MESSAGES) {
                log.removeChild(log.firstChild);
            }
            
            // Fade out after 120 seconds (2 minutes)
            setTimeout(() => { div.classList.add('faded'); }, 120000); 
        }
        
        function clearChat() { log.innerHTML = ''; }
    </script>
</body>
</html>
]]

-- Init Chat Panel (Lua)
-- ... (Logic continues below in next chunk if needed, but Replace covers the HTML/Config block)
local function CreateChatPanel()
    if IsValid(chatPanel) then chatPanel:Remove() end
    
    local x, y = GetChatPos()
    
    chatPanel = vgui.Create("DHTML")
    chatPanel:SetPos(x, y)
    chatPanel:SetSize(chatConfig.w, chatConfig.h)
    chatPanel:SetHTML(chatHTML)
    chatPanel:SetMouseInputEnabled(false) 
    chatPanel:SetKeyboardInputEnabled(false)
    chatPanel:ParentToHUD()
end

-- Init Input Panel (The text entry box)
local function CreateInputPanel()
    if IsValid(inputPanel) then inputPanel:Remove() end
    
    local x, y = GetChatPos()
    local inputY = y + chatConfig.h + 5
    
    inputPanel = vgui.Create("EditablePanel") -- Using EditablePanel for better focus handling
    inputPanel:SetSize(chatConfig.w, 40)
    inputPanel:SetPos(x, inputY)
    inputPanel:SetVisible(false)
    
    inputPanel.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(10, 10, 14, 250))
        surface.SetDrawColor(255, 255, 255, 20)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.RoundedBox(0, w-4, 0, 4, h, Color(255, 140, 0)) -- Accent on right
    end
    
    local entry = vgui.Create("DTextEntry", inputPanel)
    entry:SetPos(10, 5)
    entry:SetSize(inputPanel:GetWide() - 20, 30)
    entry:SetFont("DermaLarge")
    entry:SetDrawBackground(false)
    entry:SetTextColor(Color(255, 255, 255))
    entry:SetHistoryEnabled(false)
    
    -- Send handler
    local function SendMsg(s)
        local msg = s:GetValue()
        if msg and msg ~= "" then
            -- RunConsoleCommand is the standard way to run commands from client
            RunConsoleCommand("say", msg) 
        end
        inputPanel:SetVisible(false)
        gui.EnableScreenClicker(false)
        s:SetText("")
    end

    entry.OnEnter = function(s)
        SendMsg(s)
    end
    
    entry.OnKeyCodeTyped = function(s, code)
        if code == KEY_ESCAPE then
            inputPanel:SetVisible(false)
            gui.EnableScreenClicker(false)
            gui.HideGameUI()
        elseif code == KEY_ENTER then
            SendMsg(s)
        end
    end
    
    inputPanel.entry = entry
end

hook.Add("InitPostEntity", "ArtoRP.Chat.Init", function()
    CreateChatPanel()
    CreateInputPanel()
end)

-- Re-create on resize
hook.Add("OnScreenSizeChanged", "ArtoRP.Chat.Resize", function()
    CreateChatPanel()
    CreateInputPanel()
end)

-- Chat Hooks
hook.Add("StartChat", "ArtoRP.Chat.Start", function(isTeamChat)
    if not IsValid(inputPanel) then CreateInputPanel() end
    
    inputPanel:SetVisible(true)
    inputPanel:MakePopup()
    inputPanel.entry:RequestFocus()
    gui.EnableScreenClicker(true) -- Force mouse mode
    
    return true -- Suppress default
end)

hook.Add("FinishChat", "ArtoRP.Chat.Finish", function()
    if IsValid(inputPanel) then
        inputPanel:SetVisible(false)
        gui.EnableScreenClicker(false)
    end
end)

hook.Add("ChatText", "ArtoRP.Chat.FeedServer", function(index, name, text, type)
    if not IsValid(chatPanel) then return end
    
    if type == "chat" then return end -- Handled by OnPlayerChat
    
    -- Escape
    local content = string.gsub(text, "'", "\\'")
    
    -- Color detection (Server msg vs Connect)
    local msgType = "server"
    if type == "joinleave" then msgType = "connect" end
    
    -- JS Call
    -- addMessage(type, sender, r,g,b, text)
    local js = string.format("addMessage('%s', null, 0,0,0, '%s')", msgType, content)
    chatPanel:RunJavascript(js)
    
    return true -- Suppress
end)

hook.Add("OnPlayerChat", "ArtoRP.Chat.FeedPlayer", function(ply, text, isTeam, isDead)
    if not IsValid(chatPanel) then return end
    
    local name = IsValid(ply) and ply:Nick() or "Console"
    
    -- Rank Prefix
    if IsValid(ply) then
        if ply:IsSuperAdmin() then name = "[OWNER] " .. name
        elseif ply:IsAdmin() then name = "[ADMIN] " .. name
        end
        
        -- VIP Prefix (Independent)
        if ply:GetNW2Bool("ArtoRP_IsVIP", false) then name = "[VIP] " .. name end
    end

    local col = IsValid(ply) and team.GetColor(ply:Team()) or Color(0, 255, 0)
    
    -- Escape
    local content = string.gsub(text, "'", "\\'")
    name = string.gsub(name, "'", "\\'")
    
    local js = string.format("addMessage('chat', '%s', %d,%d,%d, '%s')", 
        name, col.r, col.g, col.b, content)
    chatPanel:RunJavascript(js)
    
    return true
end)

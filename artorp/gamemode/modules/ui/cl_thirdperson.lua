-- Third Person Camera System for ArtoRP

local tpEnabled = false
local tpDist = 100
local tpSmoothOrigin = Vector(0, 0, 0)
local tpSmoothAngles = Angle(0, 0, 0)

-- Function to Toggle TPS
local function ToggleTPS()
    tpEnabled = not tpEnabled
    if tpEnabled then
        -- chat.AddText(Color(0, 255, 0), "[ArtoRP] Third Person: ENABLED")
        if LocalPlayer() and IsValid(LocalPlayer()) then
            tpSmoothOrigin = LocalPlayer():GetPos()
        end
    else
        -- chat.AddText(Color(255, 0, 0), "[ArtoRP] Third Person: DISABLED")
    end
end

-- Key Bind: Left Control OR Caps Lock
hook.Add("PlayerButtonDown", "ArtoRP.TPSKey", function(ply, button)
    if not IsFirstTimePredicted() then return end 
    
    if button == KEY_CAPSLOCK then
        ToggleTPS()
    end
end)

-- The Camera Logic
hook.Add("CalcView", "ArtoRP.TPSCalcView", function(ply, pos, angles, fov)
    if not tpEnabled then return end
    if not IsValid(ply) or not ply:Alive() then return end
    
    local viewAng = angles
    
    -- "Over the Shoulder" adjusted
    local startPos = ply:EyePos()
    
    -- Camera Offsets
    local offset = viewAng:Forward() * -80 -- Distance behind
                 + viewAng:Right() * 20    -- Right offset
                 + viewAng:Up() * 0        -- Height offset (Raised from -5)
    
    local targetPos = startPos + offset
    
    -- Wall Trace (Prevent seeing through walls)
    local tr = util.TraceHull({
        start = startPos,
        endpos = targetPos,
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4),
        filter = ply,
        mask = MASK_SOLID_BRUSHONLY
    })
    
    if tr.Hit then
        targetPos = tr.HitPos + tr.HitNormal * 2
    end
    
    -- Smooth Logic (Direct set for responsiveness)
    tpSmoothOrigin = targetPos
    
    return {
        origin = tpSmoothOrigin,
        angles = angles,
        fov = fov,
        drawviewer = true
    }
end)

-- Optional: Draw Crosshair in TPS? (Usually handled by HUD)

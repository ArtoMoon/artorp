include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos()
    local ang = self:GetAngles()

    -- Açıyı ayarla (printer'ın üstüne gelsin)
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)

    -- Floating Effect
    local sin = math.sin(CurTime() * 2) * 2

    cam.Start3D2D(pos + ang:Up() * 11.2, ang, 0.1)
        -- Background Box
        draw.RoundedBox(4, -100, -70, 200, 150, Color(20, 20, 25, 240))
        
        -- Title
        draw.SimpleText("Money Printer", "DermaLarge", 0, -50, Color(255, 140, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Money
        local money = self:GetStoredMoney()
        draw.SimpleText("$" .. money, "DermaDefaultBold", 0, -15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Info Row (Owner | Health)
        local owner = self:GetItemOwner()
        local ownerName = IsValid(owner) and string.sub(owner:Nick(), 1, 10) or "Unknown"
        local hp = math.max(0, math.floor(self:Health()))
        
        -- Sağ ve Sol tarafa hizalama
        draw.SimpleText(ownerName, "DermaDefault", -90, 10, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        local hpColor = Color(150, 255, 150)
        if hp < 50 then hpColor = Color(255, 200, 0) end
        if hp < 25 then hpColor = Color(255, 50, 50) end
        draw.SimpleText("HP: " .. hp .. "%", "DermaDefault", 90, 10, hpColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        
        -- HEAT BAR
        local heat = self:GetHeat()
        local barColor = Color(0, 255, 100)
        if heat > 50 then barColor = Color(255, 200, 0) end
        if heat > 80 then barColor = Color(255, 50, 50) end
        
        draw.RoundedBox(0, -80, 35, 160, 10, Color(50,50,50))       -- Background
        draw.RoundedBox(0, -80, 35, 160 * (heat/100), 10, barColor) -- Fill
        
        draw.SimpleText(heat .. "% HEAT", "DermaDefault", 0, 40, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Status underneath
        local status = self:GetIsOn() and "RUNNING" or "STOPPED"
        if heat > 90 then status = "CRITICAL!" end
        draw.SimpleText(status, "DermaDefaultBold", 0, 60, barColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
    cam.End3D2D()
end

include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    -- 3D2D Yazi (Opsiyonel)
    local pos = self:GetPos() + Vector(0, 0, 40)
    local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
    
    -- Yakinlardaysa cani goster
    if LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 300*300 then
        cam.Start3D2D(pos, ang, 0.1)
            draw.SimpleText("Kaya Kaynagi", "DermaLarge", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end

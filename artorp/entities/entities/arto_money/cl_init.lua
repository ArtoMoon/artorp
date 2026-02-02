include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local amount = self:GetNWInt("Amount", 0)
    
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    
    cam.Start3D2D(self:GetPos() + self:GetUp() * 5, ang, 0.1)
        draw.SimpleText("$" .. amount, "DermaLarge", 0, 0, Color(0, 200, 80, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
    
    -- Draw other side too so it's readable from both sides
    ang:RotateAroundAxis(ang:Right(), 180)
    
    cam.Start3D2D(self:GetPos() + self:GetUp() * 5, ang, 0.1)
        draw.SimpleText("$" .. amount, "DermaLarge", 0, 0, Color(0, 200, 80, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

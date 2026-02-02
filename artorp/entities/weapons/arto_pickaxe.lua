AddCSLuaFile()

SWEP.PrintName = "Kazma" -- Pickaxe
SWEP.Author = "ArtoRP"
SWEP.Instructions = "Kaya kirmak icin sol tikla (Left click to mine)"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Category = "ArtoRP"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/c_crowbar.mdl" 
SWEP.WorldModel = "models/pickaxe.mdl"

SWEP.UseHands = true 
SWEP.HoldType = "melee2" 

if CLIENT then
    SWEP.WModelEnt = nil
    SWEP.VModelEnt = nil -- View Model Entity

    -- FPS (View Model) Custom Rendering
    function SWEP:PostDrawViewModel(vm, weapon, ply)
        if not IsValid(vm) then return end
        
        -- HIDE THE DEFAULT CROWBAR (Smart Material Hack)
        -- Loop to find the crowbar material specifically
        local materials = vm:GetMaterials()
        for k, v in pairs(materials) do
            if string.find(v, "crowbar") then
                vm:SetSubMaterial(k-1, "engine/occlusionproxy") 
            end
        end
        
        local boneid = vm:LookupBone("ValveBiped.Bip01_R_Hand")
        if not boneid then return end
        
        local pos, ang = vm:GetBonePosition(boneid)
        
        -- ADJUST FPS POSITION HERE
        pos = pos + ang:Forward() * 5.0   
        pos = pos + ang:Right() * 1.0
        pos = pos + ang:Up() * -3.0
        
        ang:RotateAroundAxis(ang:Right(), 100) 
        ang:RotateAroundAxis(ang:Forward(), 0)
        ang:RotateAroundAxis(ang:Up(), -10)
        
        if not IsValid(self.VModelEnt) then
            self.VModelEnt = ClientsideModel("models/pickaxe.mdl", RENDERGROUP_OPAQUE)
            self.VModelEnt:SetNoDraw(true)
            self.VModelEnt:SetModelScale(1.0, 0)
        end
        
        self.VModelEnt:SetPos(pos)
        self.VModelEnt:SetAngles(ang)
        self.VModelEnt:DrawModel()
    end

    -- TPS (World Model) Custom Rendering
    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()

        if IsValid(owner) then
            -- Don't draw world model for ourselves in first person (prevents clipping)
            if owner == LocalPlayer() and not owner:ShouldDrawLocalPlayer() then return end

            -- Weapon is being held by a player
            local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand")
            if not boneid then return end

            local pos, ang = owner:GetBonePosition(boneid)
            
            --[[ 
                ADJUST THESE VALUES TO FIX POSITION 
                Kazma pozisyonunu buradan ayarlayabiliriz.
            ]]
            pos = pos + ang:Forward() * 4.0      -- Move forward
            pos = pos + ang:Right() * 1.0        -- Move right
            pos = pos + ang:Up() * 0             
            
            -- Rotate to align handle with arm
            ang:RotateAroundAxis(ang:Right(), 90) 
            ang:RotateAroundAxis(ang:Forward(), 0) 
            ang:RotateAroundAxis(ang:Up(), 0)

            if not IsValid(self.WModelEnt) then
                self.WModelEnt = ClientsideModel("models/pickaxe.mdl", RENDERGROUP_OPAQUE)
                self.WModelEnt:SetNoDraw(true)
                self.WModelEnt:SetModelScale(1.0, 0) 
            end

            self.WModelEnt:SetPos(pos)
            self.WModelEnt:SetAngles(ang)
            self.WModelEnt:DrawModel()
        else
            -- Dropped on ground
            self:DrawModel()
        end
    end
    
    function SWEP:Holster()
        if CLIENT and IsValid(self.Owner) then
            local vm = self.Owner:GetViewModel()
            if IsValid(vm) then vm:SetSubMaterial(0, nil) end
        end
        return true
    end

    function SWEP:OnRemove()
        if CLIENT and IsValid(self.Owner) then
            local vm = self.Owner:GetViewModel()
            if IsValid(vm) then vm:SetSubMaterial(0, nil) end
        end
        if IsValid(self.WModelEnt) then self.WModelEnt:Remove() end
        if IsValid(self.VModelEnt) then self.VModelEnt:Remove() end
    end
end 

function SWEP:Initialize()
    self:SetHoldType("melee2")
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5) -- Swing rate
    
    self:SendWeaponAnim(ACT_VM_HITCENTER)
    self:EmitSound("Weapon_Crowbar.Single")
    
    self.Owner:SetAnimation(PLAYER_ATTACK1)

    if CLIENT then return end

    -- Raycast to see what we hit
    local tr = util.TraceLine({
        start = self.Owner:GetShootPos(),
        endpos = self.Owner:GetShootPos() + (self.Owner:GetAimVector() * 100), -- 100 units range
        filter = self.Owner
    })

    if tr.Hit then
        self:EmitSound("Physics.ConcreteImpact")
        
        local ent = tr.Entity
        
        -- If we hit a valid entity
        if IsValid(ent) then
            -- Apply damage
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(10)
            dmginfo:SetDamageType(DMG_CLUB)
            dmginfo:SetAttacker(self.Owner)
            dmginfo:SetInflictor(self)
            
            ent:TakeDamageInfo(dmginfo)
            
            -- Apply force
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:ApplyForceOffset(self.Owner:GetAimVector() * 5000, tr.HitPos)
            end
            
            -- Mining logic placeholder
            -- if ent:GetClass() == "my_rock_entity" then ... end
            print("Kazma vurdu: " .. tostring(ent))
        end
        
        -- Effect
        local effectdata = EffectData()
        effectdata:SetOrigin(tr.HitPos)
        effectdata:SetNormal(tr.HitNormal)
        effectdata:SetMagnitude(1)
        effectdata:SetScale(1)
        effectdata:SetRadius(1)
        util.Effect("Sparks", effectdata)
    end
end

function SWEP:SecondaryAttack()
    -- No secondary attack
end

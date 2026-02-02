AddCSLuaFile()
if SERVER then
    resource.AddWorkshop("3647915132") -- "der wallet" / ArtoRP Wallet Model
end

SWEP.PrintName = "Wallet"
SWEP.Author = "ArtoRP"
SWEP.Instructions = "Left Click to Manage Money"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Category = "ArtoRP"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

-- Use Pistol as base, attach money to it
-- Using c_grenade because it renders hands reliably and has a good grip
SWEP.ViewModel = "models/weapons/c_grenade.mdl"
SWEP.WorldModel = "models/wallet.mdl"

SWEP.UseHands = true 
SWEP.HoldType = "pistol" 

if CLIENT then
    SWEP.WepSelectIcon = surface.GetTextureID("weapons/swep")
    SWEP.BounceWeaponIcon = false
    
    SWEP.WalletModel = nil
    
    function SWEP:PostDrawViewModel(vm, weapon, ply)
        if not IsValid(vm) then return end
        
        -- Hide the grenade mesh by scaling its bone to 0
        local grenadeBone = vm:LookupBone("ValveBiped.Grenade_body")
        if grenadeBone then
            vm:ManipulateBoneScale(grenadeBone, Vector(0,0,0))
        end
        
        -- Create the wallet model if it doesn't exist
        if not IsValid(self.WalletModel) then
            -- Try to create the model
            self.WalletModel = ClientsideModel("models/wallet.mdl", RENDERGROUP_OPAQUE)
            
            if IsValid(self.WalletModel) then
                self.WalletModel:SetNoDraw(true)
                self.WalletModel:SetModelScale(0.8, 0) -- Slightly bigger
                print("[ArtoRP] ✓ Wallet model created successfully!")
                chat.AddText(Color(0, 255, 0), "[ArtoRP] ✓ Wallet model loaded!")
            else
                print("[ArtoRP] ✗ FAILED to create wallet model!")
                chat.AddText(Color(255, 0, 0), "[ArtoRP] ✗ Model creation FAILED!")
                return -- Don't try to render if model failed
            end
        end
        
        -- Get hand bone
        local boneid = vm:LookupBone("ValveBiped.Bip01_R_Hand")
        if not boneid then 
            print("[ArtoRP] ✗ Could not find hand bone!")
            return 
        end
        
        local pos, ang = vm:GetBonePosition(boneid)
        
    
        pos = pos + ang:Forward() * 5
        pos = pos + ang:Right() * 5
        pos = pos + ang:Up() * -0.5
        
        ang:RotateAroundAxis(ang:Right(), 220)
        ang:RotateAroundAxis(ang:Forward(), 180)
        self.WalletModel:SetPos(pos)
        self.WalletModel:SetAngles(ang)
        self.WalletModel:SetRenderMode(RENDERMODE_NORMAL)
        self.WalletModel:DrawModel()
    end

    function SWEP:Holster()
        if IsValid(self.WalletModel) then self.WalletModel:Remove() end
        return true
    end
    
    function SWEP:OnRemove()
        if IsValid(self.WalletModel) then self.WalletModel:Remove() end
    end
end

function SWEP:PrimaryAttack()
    if SERVER then return end
    if not IsFirstTimePredicted() then return end
    
    -- Open Wallet UI
    if IsValid(ArtoRP_WalletPanel) then ArtoRP_WalletPanel:Remove() end
    
    ArtoRP_WalletPanel = vgui.Create("DHTML")
    ArtoRP_WalletPanel:SetSize(400, 300)
    ArtoRP_WalletPanel:Center()
    ArtoRP_WalletPanel:MakePopup()
    ArtoRP_WalletPanel:SetHTML([[
    <!DOCTYPE html>
    <html>
    <head>
        <link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@600;700&display=swap" rel="stylesheet">
        <style>
            body { 
                margin: 0; background: rgba(20, 20, 25, 0.95); 
                font-family: 'Rajdhani', sans-serif; 
                border: 1px solid rgba(255,255,255,0.1);
                border-top: 3px solid #00C851;
                display: flex; flex-direction: column; align-items: center; padding: 20px;
                overflow: hidden;
            }
            .title { color: white; font-size: 24px; font-weight: 700; margin-bottom: 20px; letter-spacing: 1px; }
            input {
                background: rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.2);
                padding: 10px; color: white; width: 80%; font-size: 20px; text-align: center;
                margin-bottom: 20px; font-family: inherit; font-weight: 700; outline: none;
                border-radius: 4px;
            }
            input:focus { border-color: #00C851; }
            .btn-group { display: flex; gap: 10px; width: 90%; }
            button {
                flex: 1; padding: 15px; border: none; cursor: pointer;
                font-family: inherit; font-weight: 700; font-size: 16px;
                transition: 0.2s; border-radius: 4px; color: white;
            }
            .btn-drop { background: #CC0000; }
            .btn-drop:hover { background: #ff4444; }
            .btn-give { background: #00C851; }
            .btn-give:hover { background: #00E25B; }
            .btn-close { background: transparent; color: #888; font-size: 12px; margin-top: 15px; }
            .btn-close:hover { color: white; }
        </style>
    </head>
    <body>
        <div class="title">MY WALLET</div>
        <input type="number" id="amount" placeholder="Amount ($)" autofocus>
        
        <div class="btn-group">
            <button class="btn-drop" onclick="doAction('drop')">DROP</button>
            <button class="btn-give" onclick="doAction('give')">GIVE</button>
        </div>
        
        <button class="btn-close" onclick="glua.close()">Close Wallet</button>

        <script>
            function doAction(act) {
                const amt = document.getElementById('amount').value;
                if(!amt || amt <= 0) return;
                glua.action(act, amt);
            }
        </script>
    </body>
    </html>
    ]])
    
    ArtoRP_WalletPanel:AddFunction("glua", "close", function()
        if IsValid(ArtoRP_WalletPanel) then ArtoRP_WalletPanel:Remove() end
    end)
    
    ArtoRP_WalletPanel:AddFunction("glua", "action", function(act, amount)
        net.Start("ArtoRP.WalletAction")
        net.WriteString(act)
        net.WriteInt(tonumber(amount) or 0, 32)
        net.SendToServer()
        
        if IsValid(ArtoRP_WalletPanel) then ArtoRP_WalletPanel:Remove() end
    end)
    
    self:SetNextPrimaryFire(CurTime() + 1)
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    -- Reduce size of the entity itself (for when it's dropped on the ground)
    self:SetModelScale(0.1, 0) 
end

if CLIENT then
    -- Reuse the same model reference for world drawing if possible, or make a new one.
    -- Better uniqueness for world model rendering:
    SWEP.WModelEnt = nil

    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()

        if IsValid(owner) then
            -- Weapon is being held by a player
            local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand")
            if not boneid then return end

            local pos, ang = owner:GetBonePosition(boneid)
            
            -- Apply "Best Settings" for World Model as well
            pos = pos + ang:Forward() * 4
            pos = pos + ang:Right() * 1.3
            pos = pos + ang:Up() * -0.5
            
            ang:RotateAroundAxis(ang:Right(), 70)

            if not IsValid(self.WModelEnt) then
                self.WModelEnt = ClientsideModel("models/wallet.mdl", RENDERGROUP_OPAQUE)
                self.WModelEnt:SetNoDraw(true)
                self.WModelEnt:SetModelScale(0.6, 0) -- Match the ViewModel scale
            end

            self.WModelEnt:SetPos(pos)
            self.WModelEnt:SetAngles(ang)
            self.WModelEnt:DrawModel()
        else
            -- Weapon is dropped on the ground
            self:DrawModel()
        end
    end
    
    -- Cleanup world model prop on remove
    local oldRemove = SWEP.OnRemove
    function SWEP:OnRemove()
        if oldRemove then oldRemove(self) end -- Call the viewmodel remove logic
        if IsValid(self.WModelEnt) then self.WModelEnt:Remove() end
    end
end

function SWEP:SecondaryAttack()
    
end

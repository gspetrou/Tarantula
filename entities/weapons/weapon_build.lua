AddCSLuaFile()
SWEP.Author = "Gonzalolog"
SWEP.Instructions = ""
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = "models/weapons/c_arms.mdl"
SWEP.UseHands = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.PrintName = "Building"
SWEP.Category = "Build RP"
SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

function SWEP:PrimaryAttack()
    if (IsFirstTimePredicted() and CLIENT and IsValid(self.Owner.BuildModel)) then
        net.Start("trn.Building.SpawnProp")
        net.WriteVector(self.Owner.BuildModel:GetPos())
        net.WriteAngle(self.Owner.BuildModel:GetAngles())
        net.SendToServer()
        self.Owner.BuildModel:Remove()
    end
end

function SWEP:SecondaryAttack()
    if (CLIENT) then
        RunConsoleCommand("trn_openbuildmenu")
    end
end

function SWEP:Reload()
    if (CLIENT and IsValid(self.Owner.BuildModel)) then
        self.Owner.BuildModel:Remove()
    end
end

function SWEP:Think()
    if (CLIENT and IsValid(self.Owner.BuildModel)) then
        local mdl = self.Owner.BuildModel
        local min, max = mdl:GetCollisionBounds()

        local tr = util.TraceHull({
            start = self.Owner:GetShootPos(),
            endpos = self.Owner:GetShootPos() + (self.Owner:GetAimVector() * 150),
            filter = self.Owner,
            mins = min,
            maxs = max,
            mask = MASK_SHOT_HULL
        })

        mdl:SetPos(tr.HitPos)
        mdl:SetColor(tr.Hit and Color(100, 255, 50) or Color(255, 100, 50))

        if (self.Owner:KeyDown(IN_USE)) then
            mdl:SetAngles(mdl:GetAngles() + self.LastView - self.Owner:EyeAngles())
            self.Owner:SetEyeAngles(self.LastView)
            local deltaA = self.Owner:EyeAngles()
            local deltaB = self.Owner:EyeAngles()
        else
            self.LastView = self.Owner:EyeAngles()
        end
    end
end

function SWEP:ShouldDropOnDie()
    return false
end

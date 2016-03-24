Vengeance = class({}, nil, UnitEntity)

function Vengeance:constructor(round, owner, target, facing, ability)
    getbase(Vengeance).constructor(self, round, "npc_dota_hero_vengefulspirit", target, owner.unit:GetTeamNumber())

    self.owner = owner.owner
    self.hero = owner
    self.health = 3
    self.size = 64
    self.collisionType = COLLISION_TYPE_RECEIVER

    local unit = self:GetUnit()
    unit:SetControllableByPlayer(owner.owner.id, true)
    unit:FindAbilityByName("venge_q"):SetLevel(1)
    unit.hero = self

    self:CreateParticles()
    self:AddNewModifier(self.hero, ability, "modifier_venge_r", { duration = 10 })
    self:AddNewModifier(self.hero, ability, "modifier_venge_r_visual", {})
    self:SetFacing(facing)
    self:SetPos(target)
end

function Vengeance:CreateParticles()
    self.healthCounter = ParticleManager:CreateParticle("particles/venge_r/venge_r_counter.vpcf", PATTACH_CUSTOMORIGIN, self.unit)
    ParticleManager:SetParticleControl(self.healthCounter, 0, Vector(self.position.x, self.position.y, self.position.z + 200))
    ParticleManager:SetParticleControl(self.healthCounter, 1, Vector(0, self.health, 0))

    self.rangeIndicator = ParticleManager:CreateParticle("particles/aoe_marker.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.unit)
    ParticleManager:SetParticleControl(self.rangeIndicator, 0, self:GetPos())
    ParticleManager:SetParticleControl(self.rangeIndicator, 1, Vector(650, 1, 1))
    ParticleManager:SetParticleControl(self.rangeIndicator, 2, Vector(0, 74, 127))
    ParticleManager:SetParticleControl(self.rangeIndicator, 3, Vector(10, 0, 0))
end

function Vengeance:SetPos(pos)
    getbase(Vengeance).SetPos(self, pos)

    ParticleManager:SetParticleControl(self.healthCounter, 0, Vector(self.position.x, self.position.y, self.position.z + 200))
    ParticleManager:SetParticleControl(self.rangeIndicator, 0, self:GetPos())
end

function Vengeance:Remove()
    getbase(Vengeance).Remove(self)

    ParticleManager:DestroyParticle(self.healthCounter, false)
    ParticleManager:ReleaseParticleIndex(self.healthCounter)

    ParticleManager:DestroyParticle(self.rangeIndicator, false)
    ParticleManager:ReleaseParticleIndex(self.rangeIndicator)

    ImmediateEffectPoint("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, self.hero, self:GetPos())
end

function Vengeance:Damage(source)
    if source.owner ~= self.hero then
        self.health = self.health - 1
    end

    ParticleManager:SetParticleControl(self.healthCounter, 1, Vector(0, self.health, 0))

    if self.health == 0 then
        self:Destroy()
    end
end

function Vengeance:CollidesWith(source)
    return true
end
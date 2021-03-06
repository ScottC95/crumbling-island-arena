modifier_tusk_e = class({})
if IsServer() then
    function modifier_tusk_e:OnCreated(kv)
        local speed = 600

        if self:GetParent():HasModifier("modifier_tusk_r") then
            speed = 1200
        end

        local index = ParticleManager:CreateParticle("particles/tusk_e/tusk_e.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
        ParticleManager:SetParticleControl(index, 2, Vector(speed, 1, 1))
        ParticleManager:SetParticleControl(index, 3, Vector(160, 1, 120))
        ParticleManager:SetParticleControlEnt(index, 4, self:GetParent(), PATTACH_POINT_FOLLOW, nil, self:GetParent():GetOrigin(), true)
        self:AddParticle(index, false, false, -1, false, false)
        self:GetParent():AddNoDraw()
    end

    function modifier_tusk_e:OnDestroy()
        self:GetParent():RemoveNoDraw()
        self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_TELEPORT_END, 1.5)
    end
end

function modifier_tusk_e:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true
    }

    return state
end

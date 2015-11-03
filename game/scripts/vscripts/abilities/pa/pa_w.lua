pa_w = class({})

function pa_w:OnSpellStart()
    local caster = self:GetCaster()
    local hero = caster.hero
    hero:EmitSound("DOTA_Item.Daedelus.Crit")

    Timers:CreateTimer(0.3,
        function()
            local particle = "particles/econ/items/axe/axe_weapon_bloodchaser/axe_attack_blur_counterhelix_bloodchaser_b.vpcf"
            ImmediateEffect(particle, PATTACH_ABSORIGIN_FOLLOW, caster)

            Spells:AreaDamage(hero, hero:GetPos(), 256)
            GridNav:DestroyTreesAroundPoint(hero:GetPos(), 256, true)
        end
    )

end

function pa_w:GetCastAnimation()
    return ACT_DOTA_ATTACK_EVENT
end
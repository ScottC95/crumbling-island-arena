undying_q = class({})
local self = undying_q

LinkLuaModifier("modifier_undying_q", "abilities/undying/modifier_undying_q", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_undying_q_health", "abilities/undying/modifier_undying_q_health", LUA_MODIFIER_MOTION_NONE)

function self:OnSpellStart()
    Wrappers.DirectionalAbility(self, 900)

    local hero = self:GetCaster().hero
    local target = self:GetCursorPosition()

    FX("particles/units/heroes/hero_undying/undying_decay.vpcf", PATTACH_WORLDORIGIN, hero, {
        cp0 = target,
        cp1 = Vector(300, 0, 0),
        cp2 = hero:GetPos(),
        release = true
    })

    local stacks = 0

    hero:AreaEffect({
        filter = Filters.Area(target, 300),
        filterProjectiles = true,
        onlyHeroes = true,
        modifier = { name = "modifier_undying_q", ability = self, duration = 1.0 },
        sound = "Arena.Undying.HitQ",
        action = function(victim)
            FX("particles/units/heroes/hero_undying/undying_decay_strength_xfer.vpcf", PATTACH_ABSORIGIN, hero, {
                cp0 = { ent = victim, point = "attach_hitloc" },
                cp1 = { ent = hero },
                cp2 = { ent = hero }
            })

            stacks = stacks + 1
        end
    })

    for i = 1, stacks do
        hero:AddNewModifier(hero, self, "modifier_undying_q_health", { duration = 7 })
    end

    hero:EmitSound("Arena.Undying.CastQ", target)
    ScreenShake(target, 5, 150, 0.45, 3000, 0, true)
end

function self:GetCastAnimation()
    return ACT_DOTA_UNDYING_DECAY
end

function self:GetPlaybackRateOverride()
    return 1.66
end
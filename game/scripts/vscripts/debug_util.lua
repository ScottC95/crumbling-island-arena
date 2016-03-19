Debug = Debug or {
    enableEndCheck = false,
    displayDebug = true,
    debugHeroName = "npc_dota_hero_tiny",
    debugHero = nil
}

function Debug:OnTestEverything()
end

function Debug:OnTakeDamage(eventSourceIndex, args)
    mode.Players[args.PlayerID].hero:Damage()
end

function Debug:OnHealHealth(eventSourceIndex, args)
    mode.Players[args.PlayerID].hero:Heal()
end

function Debug:OnCheckEnd()
    mode.round:CheckEndConditions()
end

function Debug:OnHealDebugHero()
    Debug.debugHero.unit:SetHealth(5)
end

function Debug:OnResetLevel(eventSourceIndex, args)
    mode.Level:Reset()
end

function Debug:OnCreateTestHero()
    local round = GameRules.GameMode.round
    local hero = round:LoadHeroClass(Debug.debugHeroName)

    hero:SetUnit(CreateUnitByName(Debug.debugHeroName, Vector(0, 0, 0), true, nil, nil, DOTA_TEAM_BADGUYS))
    hero:Setup()

    local _, first = next(round.players)
    hero.unit:SetControllableByPlayer(first.id, true)

    Debug.debugHero = hero

    round.spells:AddDynamicEntity(hero)
end

function InjectFreeSelection()
    Hero.SetOwner = function(self, owner)
        self.owner = owner
        self.unit:SetControllableByPlayer(owner.id, true)
    end
end

function InjectEndCheck(round)
    local original = round.CheckEndConditions
    local new =
        function()
            if enableEndCheck then
                original(round)
            end
        end

    round.CheckEndConditions = new
end

function InjectProjectileDebug()
    local original = Spells.ThinkFunction
    local new =
        function(dt)
            if displayDebug then
                for _, projectile in ipairs(Projectiles) do
                    DebugDrawCircle(projectile.position, Vector(0, 255, 0), 255, projectile.radius, false, THINK_PERIOD)
                end
            end

            return original(dt)
        end

    Spells.ThinkFunction = new
end

function InjectAreaDebug()
    local original = Spells.AreaDamage
    local new =
        function(self, hero, point, area, action)
            if displayDebug then
                DebugDrawCircle(point, Vector(0, 255, 0), 255, area, false, 1)
            end

            return original(nil, hero, point, area, action)
        end

    Spells.AreaDamage = new
end

function CheckAndEnableDebug()
    local cheatsEnabled = Convars:GetInt("sv_cheats") == 1

    CustomNetTables:SetTableValue("main", "debug", { enabled = cheatsEnabled })

    if not cheatsEnabled then
        return
    end

    GameRules.GameMode.heroSelection.SelectionTimerTime = 20000
    GameRules.GameMode.heroSelection.PreGameTime = 0

    --InjectHero(GameRules.GameMode.round)
    --InjectEndCheck(GameRules.GameMode.round)

    CustomGameEventManager:RegisterListener("debug_take_damage", Debug.OnTakeDamage)
    CustomGameEventManager:RegisterListener("debug_heal_health", Debug.OnHealHealth)
    CustomGameEventManager:RegisterListener("debug_heal_debug_hero", Debug.OnHealDebugHero)
    CustomGameEventManager:RegisterListener("debug_switch_end_check", function() Debug.enableEndCheck = not Debug.enableEndCheck end)
    CustomGameEventManager:RegisterListener("debug_switch_debug_display", function() Debug.displayDebug = not Debug.displayDebug end)
    CustomGameEventManager:RegisterListener("debug_check_end", Debug.OnCheckEnd)
    CustomGameEventManager:RegisterListener("debug_reset_level", Debug.OnResetLevel)
    CustomGameEventManager:RegisterListener("debug_create_test_hero", Debug.OnCreateTestHero)
    CustomGameEventManager:RegisterListener("debug_test_everything", Debug.OnTestEverything)

    --InjectProjectileDebug()
    --InjectAreaDebug()
    InjectFreeSelection()

    ULTS_TIME = 1
end
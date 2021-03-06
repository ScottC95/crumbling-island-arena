SECOND_STAGE_OBSTRUCTOR = "Layer2Obstructor"
THIRD_STAGE_OBSTRUCTOR = "Layer3Obstructor"

MAP_HEIGHT = 3500
FINISHING_DISTANCE = 900

local function bigTransformer(x, y)
    return x, -y
end

local function smallTransformer(x, y)
    return y, x
end

MAPS = {
    ["unranked"] = { pieces = 919, prefab = "arena_big", transformer = bigTransformer },
    ["ranked_3v3"] = { pieces = 919, prefab = "arena_big", transformer = bigTransformer },
    ["ranked_2v2"] = { pieces = 579, prefab = "arena_small", transformer = smallTransformer },
}

if Level == nil then
    Level = class({})
end

function Level.LoadMap(map)
    local prefab = MAPS[map].prefab
    local pieces = require("levels/prefabs/"..prefab)
    local currentIndex = nil
    local loaded = 0

    local function LoadNext()
        local key, value = next(pieces, currentIndex)

        if key == nil then
            return nil
        end

        currentIndex = key

        return {
            classname = "prop_dynamic",
            model = "maps/prefabs/"..prefab.."/entities/"..key,
            origin = value - Vector(0, 0, 32),
            targetname = "map_part",
            name = "map_part",
            target = "map_part"
        }
    end

    local function ReportProgress(list)
        loaded = loaded + #list

        CustomGameEventManager:Send_ServerToAllClients("setup_level_loading", { progress = loaded / MAPS[map].pieces })
    end

    local function LoadingFinished()
        GameRules.GameMode.gameSetup.levelLoaded = true
    end

    Timers:CreateTimer(function()
        local list = {}

        for i = 1, 30 do
            local n = LoadNext()

            if n == nil then
                SpawnEntityListFromTableAsynchronous(list, function()
                    ReportProgress(list)
                    LoadingFinished()
                end)
                
                return 
            end

            table.insert(list, n)
        end

        SpawnEntityListFromTableAsynchronous(list, function() ReportProgress(list) end)

        return 0.35
    end)
end

function Level:constructor()
    self.parts = Entities:FindAllByName("map_part")
    self.distance = self:GetStartingDistance()
    self.shakingParts = {}
    self.fallingParts = {}
    self.indexedParts = {}
    self.particles = {}
    self.running = true
    self.pulsePosition = 0
    self.pulseDirection = 1
    self.tick = 0

    self:BuildIndex()
    self:SetupBackground()
end

function Level:GetStartingDistance()
    if GetMapName() == "ranked_2v2" then
        return 2300
    end

    return 3000
end

function Level:BuildIndex()
    for _, part in ipairs(self.parts) do
        local position = part:GetAbsOrigin()
        part.x = position.x
        part.y = position.y
        part.z = position.z
        part.defaultZ = part.z
        part.velocity = 0
        part.angles = part:GetAnglesAsVector()
        part.angleVel = Vector(0, 0, 0)
        part.health = 100

        part.offsetX = 0
        part.offsetY = 0
        part.offsetZ = 0

        local id = math.floor(position:Length2D())
        local index = self.indexedParts[id]

        if not index then
            index = {}
            self.indexedParts[id] = index
        end

        table.insert(index, part)
    end
end

function Level:DamageGroundInRadius(point, radius)
    -- TODO index points with cluster grid
    for _, part in ipairs(self.parts) do
        if part.velocity == 0 and part.health > 0 then
            local distance = (part:GetAbsOrigin() - point):Length2D()

            if distance <= radius then
                local proportion = 1 - distance / radius

                self:DamageGround(part, 60 * proportion)
            end
        end
    end

    local particle = ParticleManager:CreateParticle("particles/cracks.vpcf", PATTACH_ABSORIGIN, GameRules:GetGameModeEntity())
    ParticleManager:SetParticleControl(particle, 0, point)
    ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))

    table.insert(self.particles, particle)
end

function Level:DamageGround(part, damage)
    part.health = part.health - damage

    if part.health <= 50 then
        table.insert(self.shakingParts, part)
    end

    if part.health <= 20 and part.z >= part.defaultZ - 8 then
        part.z = part.defaultZ + (part.health / 20 - 1) * 8
        part:SetAbsOrigin(Vector(part.x, part.y, part.z))
    end

    if part.health <= 0 then
        self:LaunchPart(part)
    end
end

function Level:Reset()
    self.running = true
    self.fallingParts = {}
    self.shakingParts = {}
    self.distance = self:GetStartingDistance()
    self.pulsePosition = 0
    self.pulseDirection = 1

    for _, part in ipairs(self.parts) do
        part:SetAbsOrigin(Vector(part.x, part.y, part.defaultZ))
        part:SetAngles(0, 0, 0)
        part.velocity = 0
        part.health = 100
        part.z = part.defaultZ
        part.offsetX = 0
        part.offsetY = 0
        part.offsetZ = 0
        part.angles = Vector(0, 0, 0)
        part.angleVel = Vector(0, 0, 0)
        part:SetRenderColor(255, 255, 255)
    end

    for _, particle in ipairs(self.particles) do
        ParticleManager:DestroyParticle(particle, false)
        ParticleManager:ReleaseParticleIndex(0)
    end

    GridNav:RegrowAllTrees()
end

function Level:LaunchPart(part)
    table.insert(self.fallingParts, part)
    part.angleVel = Vector(RandomFloat(0, 2), RandomFloat(0, 2), 0)
end

function Level:Update()
    local currentIndex = self.indexedParts[self.distance]

    if currentIndex and self.running then
        for _, part in ipairs(currentIndex) do
            self:LaunchPart(part)
        end
    end

    if self.distance - 64 > FINISHING_DISTANCE then
        local shakingIndex = self.indexedParts[self.distance - 64]

        if shakingIndex then
            for _, part in ipairs(shakingIndex) do
                table.insert(self.shakingParts, part)
            end
        end
    end

    self.tick = self.tick + 1

    if self.tick % 3 == 0 then
        for _, part in ipairs(self.shakingParts) do
            if part.velocity == 0 then
                local pulseBound = (100 - part.health) * 0.8
                local pulsePosition = self.pulsePosition / 100 * pulseBound

                part:SetRenderColor(255, 255 - pulsePosition, 255 - pulsePosition)

                local amplitude = 0.8

                if part.health ~= 100 then
                    amplitude = 1 - part.health / 80
                end

                local yaw = RandomFloat(-amplitude, amplitude)
                local pitch = RandomFloat(-amplitude, amplitude)
                local roll = RandomFloat(-amplitude, amplitude)

                part:SetAngles(yaw, pitch, roll)
            end
        end
    end

    for i = #self.fallingParts, 1, -1 do
        local part = self.fallingParts[i]
        part.velocity = part.velocity + 6
        part.z = part.z - part.velocity
        part.angles = part.angles + part.angleVel
        part:SetAngles(part.angles.x, part.angles.y, part.angles.z)
        part:SetAbsOrigin(Vector(part.x + part.offsetX, part.y + part.offsetY, part.z + part.offsetZ))

        if part.z <= -MAP_HEIGHT - 200 then
            table.remove(self.fallingParts, i)
        end
    end

    for i = #self.shakingParts, 1, -1 do
        local part = self.shakingParts[i]
        
        if part.z <= -MAP_HEIGHT then
            SplashEffect(part:GetAbsOrigin())

            table.remove(self.shakingParts, i)
        end
    end

    if self.distance > FINISHING_DISTANCE then
        if not IsInToolsMode() then
            self.distance = self.distance - 1
        end
    else
        self.running = false
    end

    self.pulsePosition = self.pulsePosition + self.pulseDirection * 3

    if self.pulsePosition <= 0 and self.pulseDirection == -1 then
        self.pulsePosition = 0
        self.pulseDirection = 1
    end

    if self.pulsePosition >= 100 and self.pulseDirection == 1 then
        self.pulsePosition = 100
        self.pulseDirection = -1
    end
end

function Level:GroundAction(action)
    for _, part in ipairs(self.parts) do
        if part.z >= part.defaultZ - 8 then
            action(part)
        end
    end
end

function Level:UpdatePartPosition(part)
    part:SetAbsOrigin(Vector(part.x + part.offsetX, part.y + part.offsetY, part.z + part.offsetZ))
end

function Level:SetPartOffset(part, offsetX, offsetY)
    part.offsetX = offsetX
    part.offsetY = offsetY
    self:UpdatePartPosition(part)
end

function Level.CreateCreep(name, spawn, team, goal)
    CreateUnitByNameAsync(name, spawn, true, nil, nil, team, function(unit)
        unit:AddNewModifier(u, nil, "modifier_creep", {})
        unit:SetInitialGoalEntity(goal)
    end)
end

function Level:SetupBackground()
    local ancient = Entities:FindByName(nil, "ancient_effect")

    if not ancient then
        return
    end
    
    local effect = ParticleManager:CreateParticle("particles/dire_fx/bad_ancient_ambient.vpcf", PATTACH_ABSORIGIN, GameRules:GetGameModeEntity())
    ParticleManager:SetParticleControl(effect, 0, ancient:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(effect)

    for _, ent in pairs(Entities:FindAllByClassname("npc_dota_tower")) do
        ent:AddNewModifier(ent, nil, "modifier_tower", {})
    end

    Timers:CreateTimer(function()
        local goodSpawn = Entities:FindByName(nil, "good_creeps_start"):GetAbsOrigin()
        local badSpawn = Entities:FindByName(nil, "bad_creeps_start"):GetAbsOrigin()

        local goodGoal = Entities:FindByName(nil, "p_good_1")
        local badGoal = Entities:FindByName(nil, "p_bad_1")

        for i = 1, 3 do
            Level.CreateCreep("npc_dota_creep_badguys_melee", badSpawn, DOTA_TEAM_CUSTOM_7, badGoal)
            Level.CreateCreep("npc_dota_creep_goodguys_melee", goodSpawn, DOTA_TEAM_CUSTOM_8, goodGoal)
        end

        Level.CreateCreep("npc_dota_creep_badguys_ranged", badSpawn, DOTA_TEAM_CUSTOM_7, badGoal)
        Level.CreateCreep("npc_dota_creep_goodguys_ranged", goodSpawn, DOTA_TEAM_CUSTOM_8, goodGoal)

        return 30
    end)
end

function Level.KillCreepsInRadius(target, radius)
    for _, c in pairs(Entities:FindAllByClassnameWithin("npc_dota_creep_lane", target, radius)) do
        c:ForceKill(false)
    end
end
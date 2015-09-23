pa_q = class({})

function pa_q:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	local direction = target - caster:GetOrigin()
	local ability = self

	local maxSpeed = 800

	if direction:Length2D() == 0 then
		direction = caster:GetForwardVector()
	end

	local projectileData = {}
	projectileData.owner = caster
	projectileData.from = caster:GetOrigin()
	projectileData.to = target
	projectileData.graphics = "particles/pa_q/pa_q.vpcf"
	projectileData.radius = 64
	projectileData.heroCondition =
		function(self, target, prev, pos)
			return SegmentCircleIntersection(prev, pos, target.hero:GetAbsOrigin(), self.radius)
		end

	projectileData.heroBehaviour =
		function(self, target)
			if self.gracePeriod[target] == nil or self.gracePeriod[target] <= 0 then
				if self.owner == target then
					caster:SwapAbilities("pa_q", "pa_q_sub", true, false)
					return true
				else
					Spells:ProjectileDamage(self, target)
					self.gracePeriod[target] = 30
				end
			end

			return false
		end

	projectileData.positionMethod = 
		function(self)
			local dif = (self.owner:GetAbsOrigin() - self.position)
			dif = Vector(dif.x, dif.y, 0):Normalized()

			self.velocity = self.velocity + dif * 16
			return self.position + self.velocity / 30
		end

	projectileData.onMove = 
		function(self, prev, cur)
			for target, time in pairs(self.gracePeriod) do
				self.gracePeriod[target] = time - 1
			end
		end

	local projectile = Spells:CreateProjectile(projectileData)
	projectile.direction = Vector(direction.x, direction.y, 0):Normalized()
	projectile.velocity = projectile.direction * maxSpeed
	projectile.gracePeriod = {}
	projectile.gracePeriod[projectile.owner] = 30

	caster.pa_q_projectile = projectile

	caster:SwapAbilities("pa_q", "pa_q_sub", false, true)
	caster:FindAbilityByName("pa_q_sub"):StartCooldown(1.5)
end

function pa_q:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end
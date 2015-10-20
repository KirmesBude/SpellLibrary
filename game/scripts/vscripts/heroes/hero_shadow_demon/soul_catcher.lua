--[[Author: Bude
	Date: 8.10.2015
	Find a random target in the given range and applies the Soul Catcher modifier to it]]
function Soul_Catcher_Start ( keys )
	-- Variables
	local caster = keys.caster
	local ability = keys.ability

	local modifier_name = keys.ModifierName
	local modifier_name_disruption_invulnerable = keys.ModifierNameDisruptionInvulnerable
	local ability_name_disruption = keys.AbilityNameDisruption
	local cast_sound_name = keys.SoundNameCast
	local onhit_sound_name = keys.SoundNameOnHit

	local ability_disruption = caster:FindAbilityByName(ability_name_disruption)

	local center = ability:GetCursorPosition()
	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel()-1)

	-- Filters since ability:GetAbilityTarget... does not really work >:(
	local teamFilter = ability:GetAbilityTargetTeam()
	local typeFilter = ability:GetAbilityTargetType()
	local flagFilter = DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD

	-- Disrupted Targets
	local disruptedTargets = caster.Disruption_Targets


	-- Fire Sound
	EmitSoundOnLocationWithCaster(center, cast_sound_name, caster)

	-- Ground Particle
	-- Note: nope
	
	-- Get all the targets
	local targets = FindUnitsInRadius(caster:GetTeamNumber(), center, nil, radius, teamFilter, typeFilter, flagFilter, 0, true)

	-- Get rid of all the invulnerable and out of world targets, that or not currently disrupted by the caster
	PreProcessTable(targets, disruptedTargets)

	-- Get a target by random
	local target = targets[math.random(#targets)]

	-- Apply modifier and fire Particles ...
	if target ~= nil then
		-- Variables
		local invul = target:FindModifierByName(modifier_name_disruption_invulnerable)
		local duration = 0
		if invul ~= nil then
			duration = invul:GetRemainingTime()
		end

		-- We can not apply modifiers on an invulnerable target ;(
		target:RemoveModifierByName(modifier_name_disruption_invulnerable)
		ability:ApplyDataDrivenModifier(caster, target, modifier_name, {})
		ability_disruption:ApplyDataDrivenModifier(caster, target, modifier_name_disruption_invulnerable, {Duration = duration})

		-- Fire Sound
		EmitSoundOn(onhit_sound_name, target)

		-- Fire Particles
		local Soul_Catcher_nFXindex = ParticleManager:CreateParticle("particles/units/heroes/hero_shadow_demon/shadow_demon_soul_catcher.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
		ParticleManager:SetParticleControl(Soul_Catcher_nFXindex,0, target:GetAbsOrigin()+Vector(0,0,150))
		ParticleManager:SetParticleControl(Soul_Catcher_nFXindex,1, target:GetAbsOrigin()+Vector(0,0,150))
		ParticleManager:SetParticleControl(Soul_Catcher_nFXindex,2, target:GetAbsOrigin()+Vector(0,0,150))
		ParticleManager:SetParticleControl(Soul_Catcher_nFXindex,3, target:GetAbsOrigin()+Vector(0,0,150))
		ParticleManager:SetParticleControl(Soul_Catcher_nFXindex,4, target:GetAbsOrigin()+Vector(0,0,150))
		ParticleManager:SetParticleControl(Soul_Catcher_nFXindex,5, target:GetAbsOrigin()+Vector(0,0,150))
		ParticleManager:SetParticleControl(Soul_Catcher_nFXindex,6, target:GetAbsOrigin()+Vector(0,0,150))

		ParticleManager:ReleaseParticleIndex(Soul_Catcher_nFXindex)
	end
end

--[[Author: Bude
	Date: 8.10.2015
	Removes any invulnerable/outofworld target in the given list, if it is not currently disrupted by the caster]]
function PreProcessTable( targets, disruptedTargets)
	for i=1, #targets, 1 do
		local unit = targets[i]

		if unit:IsInvulnerable() or unit:IsOutOfGame() then
			if not TableContains(disruptedTargets, unit) then
				table.remove(targets, i)
				i=i-1
			end
		end
	end
end

function TableContains(table, handle)
	for _,thandle in pairs(table) do
		if thandle == handle then
			return true
		end
	end

	return false
end
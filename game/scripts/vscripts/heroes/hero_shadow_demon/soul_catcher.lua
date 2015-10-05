function Soul_Catcher_Start ( keys )
	local caster = keys.caster
	local ability = keys.ability

	local modifier_name = keys.ModifierName
	local modifier_name_disruption_invulnerable = keys.ModifierNameDisruptionInvulnerable
	local ability_name_disruption = keys.AbilityNameDisruption

	local center = ability:GetCursorPosition()
	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel()-1)
	local teamFilter = ability:GetAbilityTargetTeam()
	local typeFilter = ability:GetAbilityTargetType()
	local flagFilter = DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD

	-- Visuals
	local dummy = CreateUnitByName("npc_dummy_unit", center, false, caster, caster, caster:GetTeam())
	EmitSoundOn("Hero_ShadowDemon.Soul_Catcher", dummy)

	particles = ParticleManager:CreateParticle("particles/units/heroes/hero_shadow_demon/shadow_demon_soul_catcher_new.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
	ParticleManager:SetParticleControlEnt(particles, 0, dummy, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", center, true)
	ParticleManager:ReleaseParticleIndex(particles)

	dummy:ForceKill(false)

	local disruptedUnits = caster.disruptedUnits
	--PrintTable(disruptedUnits)

	local targets = FindUnitsInRadius(caster:GetTeamNumber(), center, nil, radius, teamFilter, typeFilter, flagFilter, 0, true)

	PreProcessTable(targets, disruptedUnits)

	local target = targets[math.random(#targets)]
	print(target)

	-- 
	if target ~= nil then
		local invul = target:FindModifierByName(modifier_name_disruption_invulnerable)
		local duration = 0
		if invul ~= nil then
			duration = invul:GetRemainingTime()
		end

		target:RemoveModifierByName(modifier_name_disruption_invulnerable)
		ability:ApplyDataDrivenModifier(caster, target, modifier_name, {})
		target:AddNewModifier(caster, caster:FindAbilityByName(ability_name_disruption), modifier_name_disruption_invulnerable, {Duration = duration})
	end
end

function PreProcessTable( targets, disruptedUnits)
	for i=1, #targets, 1 do
		local unit = targets[i]

		if unit:IsInvulnerable() or unit:IsOutOfGame() then
			if not TableContains(disruptedUnits, unit) then
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
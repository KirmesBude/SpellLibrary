function OnProjectileHit( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local duration = ability:GetDuration()
	local modifier_name = keys.ModifierName
	local modifier = target:FindModifierByName(modifier_name)

	local modifier_name_disruption_invulnerable = keys.ModifierNameDisruptionInvulnerable
	local ability_name_disruption = keys.AbilityNameDisruption

	local disruptedTargets = caster.Disruption_Targets

	if caster.Shadow_Poison_Targets ==  nil then
		caster.Shadow_Poison_Targets = {}
	end

	local targets = caster.Shadow_Poison_Targets

	if IsValidTarget(keys) then
		
		DoOnHitDamage(keys)
		if not TableContains(targets, target) then
			table.insert(targets, target)
		end

		if modifier == nil then
			local invul = target:FindModifierByName(modifier_name_disruption_invulnerable)
			local invul_duration = 0
			if invul ~= nil then
				invul_duration = invul:GetRemainingTime()
			end

			target:RemoveModifierByName(modifier_name_disruption_invulnerable)

			ability:ApplyDataDrivenModifier(caster, target, modifier_name, {Duration = duration})
			modifier = target:FindModifierByName(modifier_name)
			modifier:SetStackCount(1)

			target:AddNewModifier(caster, caster:FindAbilityByName(ability_name_disruption), modifier_name_disruption_invulnerable, {Duration = invul_duration})
		else
			local stackCount = modifier:GetStackCount()
			modifier:SetStackCount(stackCount+1)
			modifier:SetDuration(duration, true)
		end

		target.Shadow_Poison_StackCount = modifier:GetStackCount()

		target.Shadow_Poison_AbilityLevel = ability:GetLevel()

		if target.Shadow_Poison_nFXindex_Counter == nil then
			target.Shadow_Poison_nFXindex_Counter = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_shadow_demon/shadow_demon_shadow_poison_stackui02.vpcf", PATTACH_OVERHEAD_FOLLOW, target, caster:GetTeamNumber())
		end

		ParticleManager:SetParticleControl(target.Shadow_Poison_nFXindex_Counter, 1, Vector(0,modifier:GetStackCount(),0))
	end
end

function DoOnHitDamage(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local dmg = ability:GetAbilityDamage()
	local dmg_type = ability:GetAbilityDamageType()

	local dmg_table = {
					victim = target,
					attacker = caster,
					damage = dmg,
					damage_type = dmg_type
					}
	ApplyDamage(dmg_table)
end

function OnModifierDestroyed( keys )
	print("modifier destroyed")
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	ParticleManager:DestroyParticle(target.Shadow_Poison_nFXindex_Counter, true)
	ParticleManager:ReleaseParticleIndex(target.Shadow_Poison_nFXindex_Counter)
	target.Shadow_Poison_nFXindex_Counter = nil

	local targets = caster.Shadow_Poison_Targets

	for i=1, #targets, 1 do
		local unit = targets[i]

		if unit == target then
			table.remove(targets, i)
			break
		end
	end

	local nFXindex = ParticleManager:CreateParticle("particles/units/heroes/hero_shadow_demon/shadow_demon_shadow_poison_release.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(nFXindex, 0, target, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(nFXindex, 2, target, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(nFXindex, 3, Vector(target.stackCount,0,0))

	ParticleManager:ReleaseParticleIndex(nFXindex)

	DoReleaseDamage(keys)

	target.Shadow_Poison_StackCount = 0
end

function Release( keys )
	local caster = keys.caster
	local targets = caster.Shadow_Poison_Targets
	local modifier_name = keys.ModifierName

	if targets ~= nil then
		for i=1, #targets, 1 do
			local target = table.remove(targets, 1)

			target:RemoveModifierByName(modifier_name)
		end
	end
end

function DoReleaseDamage( keys )
	local caster = keys.caster
	local target = keys.target
	local ability_name = keys.AbilityNameDisruption
	local ability = caster:FindAbilityByName(ability_name)
	local modifier_name = keys.ModifierNameDisruptionInvulnerable
	local modifier = target:FindModifierByName(modifier_name)

	if target:HasModifier(modifier_name) and IsDisruptedFromCaster(caster, target) then
		print("disrupted target yoo")

		local remaining = modifier:GetRemainingTime()

		target:RemoveModifierByName(modifier_name)

		_DoReleaseDamage(keys)

		ability:ApplyDataDrivenModifier(caster, target, modifier_name, {Duration = remaining})
	else
		_DoReleaseDamage(keys)
	end
end

function _DoReleaseDamage( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local dmg_type = ability:GetAbilityDamageType()
	local stackCount = target.Shadow_Poison_StackCount
	local level = target.Shadow_Poison_AbilityLevel
	local max_multiply_stacks = ability:GetLevelSpecialValueFor("max_multiply_stacks", level-1)
	local stack_damage = ability:GetLevelSpecialValueFor("stack_damage", level-1)
	local bonus_stack_damage = ability:GetLevelSpecialValueFor("bonus_stack_damage", level-1)
	local dmg = 0

	if stackCount >= max_multiply_stacks then
		dmg = (stackCount-max_multiply_stacks)*bonus_stack_damage
		stackCount = max_multiply_stacks
	end

	dmg = dmg + math.pow(2,stackCount-1)*stack_damage
	
	local dmg_table = {
						victim = target,
						attacker = caster,
						damage = dmg,
						damage_type = dmg_type
						}
	ApplyDamage(dmg_table)
end

function IsValidTarget(keys)
	local caster = keys.caster
	local target = keys.target

	if (target:IsInvulnerable() and not IsDisruptedFromCaster(caster,target)) then

		return false
	end

	return true
end

function IsDisruptedFromCaster( caster, target )
	local disruptedTargets = caster.Disruption_Targets

	return TableContains(disruptedTargets, target)
end

function TableContains(table, handle)
	if table ~= nil then
		for _,thandle in pairs(table) do
			if thandle == handle then
				return true
			end
		end
	end

	return false
end
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

	if IsValidTarget(targets, disruptedTargets, target) then
		
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

function IsValidTarget(targets, disruptedTargets, target)
	if target:IsInvulnerable() or target:IsOutOfGame() then
		if TableContains(disruptedTargets, target) then
			return true
		end
	else
		return true
	end

	return false
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

	DoDamage(caster, target, ability, modifier_name)

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

function DoDamage( caster, target, ability, modifier_name )
	print("doing damage")
	local stackCount = target.Shadow_Poison_StackCount
	local level = target.Shadow_Poison_AbilityLevel
	local dmg_per_stack = ability:GetLevelSpecialValueFor("stack_damage", level-1)
	local dmg_per_stack_overlimit = ability:GetAbilityDamage()
	local dmg = 0

	if stackCount >= 5 then
		dmg = stackCount-5*dmg_per_stack_overlimit
		stackCount = 5
	end

	dmg = dmg + math.pow(2,stackCount-1)*dmg_per_stack
	
	local dmg_table = {
						victim = target,
						attacker = caster,
						damage = dmg,
						damage_type = DAMAGE_TYPE_MAGICAL
						}
	ApplyDamage(dmg_table)
end
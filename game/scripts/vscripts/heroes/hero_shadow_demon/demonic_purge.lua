--[[Author: Bude
	Date: 8.10.2015
	Slows or roots the target based on IsCreep()]]
function DemonicPurgeStart( keys )
	local target = keys.target

	if target:IsCreep() then
		Root(keys)
	end

	Slow(keys)
end

function Root( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local duration = ability:GetLevelSpecialValueFor("creep_root_duration", ability:GetLevel()-1)
	local modifier_name = keys.ModifierName_Root

	ability:ApplyDataDrivenModifier(caster, target, modifier_name, {Duration = duration})
end

--[[Author: Bude
	Date: 8.10.2015
	Applies the Demonic Purge Slow modifier with a decaying slow
	Code based on Pizzalol's venomancer venomous_gale]]
function Slow( keys )
	-- Variables
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	-- Ability variables
	local modifier_name = keys.ModifierName_Slow
	local duration = ability:GetDuration()
	local movement_slow = ability:GetLevelSpecialValueFor("movement_slow", ability_level) * -1 -- Turn it into a positive value
	local slow_intervals = ability:GetLevelSpecialValueFor("slow_rate", ability_level)
	local slow_rate = duration / slow_intervals

	-- Decay calculation
	local slow_rate_value = movement_slow / slow_intervals

	-- Remove the old timer if we are refreshing the duration
	if target.Demonic_Purge_Timer then
		Timers:RemoveTimer(target.Demonic_Purge_Timer)
	end

	-- Apply the Demonic Purge Slow modifier and set the slow amount
	ability:ApplyDataDrivenModifier(caster, target, modifier_name, {duration = duration})
	target:SetModifierStackCount(modifier_name, caster, movement_slow)

	-- Create the timer thats responsible for the decaying movement slow
	-- Save it to the target so that we can remove it later
	target.Demonic_Purge_Timer = Timers:CreateTimer(slow_rate, function()
		if IsValidEntity(target) and target:HasModifier(modifier_name) then
			local current_slow = target:GetModifierStackCount(modifier_name, caster)
			target:SetModifierStackCount(modifier_name, caster, current_slow - slow_rate_value)

			return slow_rate
		else
			return nil
		end
	end)
end

--[[Author: Bude
	Date: 8.10.2015
	Called when the modifier is destroyed. Purges and damages target]]
function DemonicPurgeModifierDestroyed( keys )
	BasicPurge(keys)
	DoDamage(keys)
end

function BasicPurge( keys )
	-- Variables
	local target = keys.target
	local bRemovePositiveBuffs = true
	local bRemoveDebuffs = false
	local bFrameOnly = true
	local bRemoveStuns = false
	local bRemoveExceptions = false

	target:Purge(bRemovePositiveBuffs, bRemoveDebuffs, bFrameOnly, bRemoveStuns, bRemoveExceptions)
end

--[[Author: Bude
	Date: 8.10.2015
	Does Damage based on AbilitySpecial]]
function DoDamage( keys )
	local caster = keys.caster
	local target = keys.target
	local ability_name = keys.AbilityNameDisruption
	local ability = caster:FindAbilityByName(ability_name)
	local modifier_name = keys.ModifierNameDisruptionInvulnerable
	local modifier = target:FindModifierByName(modifier_name)

	if target:HasModifier(modifier_name) and IsDisruptedFromCaster(caster, target) then
		-- disrupted target found

		local remaining = modifier:GetRemainingTime()

		target:RemoveModifierByName(modifier_name)

		_DoDamage(keys)

		ability:ApplyDataDrivenModifier(caster, target, modifier_name, {Duration = remaining})
	else
		_DoDamage(keys)
	end
end

function _DoDamage( keys )
	-- Variables
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

--[[Author: Bude
	Date: 8.10.2015
	Returns true if the given target is currently disrupted by the caster]]
function IsDisruptedFromCaster( caster, target )
	local disruptedTargets = caster.Disruption_Targets

	return TableContains(disruptedTargets, target)
end

function TableContains( table, handle )
	if table ~= nil then
		for _,thandle in pairs(table) do
			if thandle == handle then
				return true
			end
		end
	end

	return false
end
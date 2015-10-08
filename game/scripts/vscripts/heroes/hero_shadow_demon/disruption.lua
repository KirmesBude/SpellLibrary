--[[Author: Bude
	Date: 8.10.2015
	Hides the model for the duration of Disruption and keeps track of the target in a table]]
function DisruptionStart( keys )
	local target = keys.target
	local target_origin = GetGroundPosition(target:GetAbsOrigin(), target)
	local vAdjust = Vector(0,0,150)

	target:AddNoDraw()

	local caster = keys.caster
	if caster.Disruption_Targets == nil then
		caster.Disruption_Targets = {}
	end

	table.insert(caster.Disruption_Targets, target)

	-- Particles
	target.Disruption_nFXindex = ParticleManager:CreateParticle("particles/units/heroes/hero_shadow_demon/shadow_demon_disruption.vpcf", PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControl(target.Disruption_nFXindex, 0, target_origin+vAdjust)
end

--[[Author: Bude
	Date: 8.10.2015
	Shows the model again after the duration of Disruption and removes the target from the table]]
function DisruptionEnd( keys )

	local sound_name = keys.sound_name
	local target = keys.target

	--Stops the loop sound when the modifier ends
	StopSoundEvent(sound_name, target)

	if target ~= nil and target:GetHealth() > 0 then
		CreateIllusions( keys )
	end

	target:RemoveNoDraw()

	local caster = keys.caster
	local Disruption_Targets = caster.Disruption_Targets

	for i=1, #Disruption_Targets, 1 do
		if Disruption_Targets[i] == target then
			table.remove(Disruption_Targets, i)
			break
		end
	end

	ParticleManager:DestroyParticle(target.Disruption_nFXindex, true)
	ParticleManager:ReleaseParticleIndex(target.Disruption_nFXindex)
end

function ApplyBuffOrDebuff( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local modifiername_buff = keys.ModifierName_Buff
	local modifiername_debuff = keys.ModifierName_Debuff

	print(caster:GetTeamNumber() == target:GetTeamNumber())
	if caster:GetTeamNumber() == target:GetTeamNumber() then
		print(modifiername_buff)
		ability:ApplyDataDrivenModifier(caster, target, modifiername_buff, {})
	else
		print(modifiername_debuff)
		ability:ApplyDataDrivenModifier(caster, target, modifiername_debuff, {})
	end
end

function CreateIllusions( event )
	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerID()
	local ability = event.ability
	local unit_name = target:GetUnitName()
	local images_count = 2
	local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability:GetLevel() - 1 )
	local outgoingDamage = ability:GetLevelSpecialValueFor( "illusion_outgoing_damage", ability:GetLevel() - 1 )
	local incomingDamage = ability:GetLevelSpecialValueFor( "illusion_incoming_damage", ability:GetLevel() - 1 )

	local targetOrigin = target:GetAbsOrigin()
	local targetAngles = target:GetAngles()

	-- Stop any actions of the target otherwise its obvious which unit is real
	target:Stop()

	-- Setup a table of potential spawn positions
	-- TODO: Randomize towards SouthWest or NorthEast
	local vSpawnPos = {
		Vector( 72, -72, 0 ),		-- NorthWest
		Vector( -72, 72, 0 ),		-- SouthEast
	}

	-- At first, move the main hero to one of the random spawn positions.
	FindClearSpaceForUnit( target, targetOrigin , true )

	-- Spawn illusions
	for i=1, images_count do

		local origin = targetOrigin + table.remove( vSpawnPos, 1 )

		-- handle_UnitOwner needs to be nil, else it will crash the game.
		local illusion = CreateUnitByName(unit_name, origin, true, target, nil, caster:GetTeamNumber())
		illusion:SetPlayerID(target:GetPlayerID())
		illusion:SetControllableByPlayer(player, true)

		illusion:SetAngles( targetAngles.x, targetAngles.y, targetAngles.z )
		
		-- Level Up the unit to the targets level
		local targetLevel = target:GetLevel()
		for i=1,targetLevel-illusion:GetLevel() do
			illusion:HeroLevelUp(false)
		end

		-- Set the skill points to 0 and learn the skills of the target
		illusion:SetAbilityPoints(0)
		for abilitySlot=0,15 do
			local ability = target:GetAbilityByIndex(abilitySlot)
			if ability ~= nil then 
				local abilityLevel = ability:GetLevel()
				local abilityName = ability:GetAbilityName()
				local illusionAbility = illusion:FindAbilityByName(abilityName)
				illusionAbility:SetLevel(abilityLevel)
			end
		end

		-- Recreate the items of the target
		for itemSlot=0,5 do
			local item = target:GetItemInSlot(itemSlot)
			if item ~= nil then
				local itemName = item:GetName()
				local newItem = CreateItem(itemName, illusion, illusion)
				illusion:AddItem(newItem)
			end
		end

		-- Set the unit as an illusion
		-- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
		illusion:AddNewModifier(target, ability, "modifier_illusion", { duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage })
		
		-- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
		illusion:MakeIllusion()
		-- Set the illusion hp to be the same as the target
		illusion:ModifyHealth(target:GetHealth(), ability, false, 0)
	end
end
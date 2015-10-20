--[[Author: Bude
	Date: 8.10.2015
	Hides the model for the duration of Disruption and keeps track of the target in a table]]
function DisruptionStart( keys )
	-- Variables
	local target = keys.target
	local target_origin = GetGroundPosition(target:GetAbsOrigin(), target)
	local caster = keys.caster
	local vAdjust = Vector(0,0,150)

	-- Hide the target
	target:AddNoDraw()

	-- Initialize Disruption targets table on the caster
	if caster.Disruption_Targets == nil then
		caster.Disruption_Targets = {}
	end

	-- Adding the Disruption target to a list for interactions with other spells
	table.insert(caster.Disruption_Targets, target)

	-- Particles
	target.Disruption_nFXindex = ParticleManager:CreateParticle("particles/units/heroes/hero_shadow_demon/shadow_demon_disruption.vpcf", PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControl(target.Disruption_nFXindex, 0, target_origin+vAdjust)
end

--[[Author: Bude
	Date: 8.10.2015
	Shows the model again after the duration of Disruption and removes the target from the table]]
function DisruptionEnd( keys )
	-- Variables
	local sound_name = keys.sound_name
	local target = keys.target
	local caster = keys.caster
	local Disruption_Targets = caster.Disruption_Targets

	-- Remove the invulnerable modifier, just to be safe
	target:RemoveModifierByName("modifier_disruption_invulnerable")

	-- Stops the loop sound when the modifier ends
	StopSoundEvent(sound_name, target)

	-- Create Illusions if possible and show the target again
	if target ~= nil and target:GetHealth() > 0 then
		CreateIllusions( keys )
	end
	target:RemoveNoDraw()

	-- Remove the target from the Disruption targets table
	for i=1, #Disruption_Targets, 1 do
		if Disruption_Targets[i] == target then
			table.remove(Disruption_Targets, i)
			break
		end
	end

	-- Destroy Particles
	ParticleManager:DestroyParticle(target.Disruption_nFXindex, true)
	ParticleManager:ReleaseParticleIndex(target.Disruption_nFXindex)
end

--[[Author: Bude
	Date: 8.10.2015
	Simply applies the right visual modifier based on teams of caster and target]]
function ApplyBuffOrDebuff( keys )
	-- Variables
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local modifier_name_buff = keys.modifier_name_buff
	local modifier_name_debuff = keys.modifier_name_debuff

	if caster:GetTeam() == target:GetTeam() then
		print("buff")
		ability:ApplyDataDrivenModifier(caster, target, modifier_name_buff, {})
	else
		print("debuff")
		ability:ApplyDataDrivenModifier(caster, target, modifier_name_debuff, {})
	end
end

--[[Author: Bude, Noya
	Date: 8.10.2015
	Creates Illusions based on AbilitySpecials in accordance to how disruption behaves
	Code based on Noya's implementation of naga_siren mirror_image]]
function CreateIllusions( event )
	-- Variables
	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerID()
	local ability = event.ability
	local unit_name = target:GetUnitName()
	local images_count = ability:GetLevelSpecialValueFor( "illusion_count" , ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability:GetLevel() - 1 )
	local outgoingDamage = ability:GetLevelSpecialValueFor( "illusion_outgoing_damage", ability:GetLevel() - 1 )
	local incomingDamage = ability:GetLevelSpecialValueFor( "illusion_incoming_damage", ability:GetLevel() - 1 )

	local targetOrigin = target:GetAbsOrigin()
	local targetAngles = target:GetAngles()

	-- Stop any actions of the target otherwise its obvious which unit is real
	target:Stop()

	-- Setup a table of potential spawn positions
	-- Note: It's stupid but this more or less results in right behaviour for standard disruption
	local vSpawnPos = {}

	local vector1 = Vector( 72, -72, 0 )
	local vector2 = Vector( 72, 72, 0)

	for i=1, math.ceil(images_count/4) do
		table.insert(vSpawnPos, i*vector1)
		table.insert(vSpawnPos, -i*vector1)
		table.insert(vSpawnPos, i*vector2)
		table.insert(vSpawnPos, -i*vector2)
	end

	-- Reposition target
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
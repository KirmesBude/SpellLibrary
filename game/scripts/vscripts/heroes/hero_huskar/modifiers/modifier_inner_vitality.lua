if modifier_inner_vitality == nil then
    modifier_inner_vitality = class({})
end

--[[
    Author: Bude
    Date: 14.10.2015.
    Checks target health every interval and adjusts health regen accordingly
]]--

function modifier_inner_vitality:IsBuff()
    return 1
end

function modifier_inner_vitality:IsPurgable()
    return 1
end

function modifier_inner_vitality:OnCreated()
    self.inner_vitality_heal = self:GetAbility():GetSpecialValueFor( "heal" )
    self.inner_vitality_attrib_bonus = self:GetAbility():GetSpecialValueFor( "attrib_bonus" )
    self.inner_vitality_hurt_attrib_bonus = self:GetAbility():GetSpecialValueFor( "hurt_attrib_bonus" )
    self.inner_vitality_hurt_percent = self:GetAbility():GetSpecialValueFor("hurt_percent")
    self.heal_amount = 0

    if IsServer() then
        --print("Created")
        self:GetParent():CalculateStatBonus()

        local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_huskar/huskar_inner_vitality.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
        self:AddParticle( nFXIndex, false, false, -1, false, false )

        self:StartIntervalThink(0.1)
    end
end

function modifier_inner_vitality:OnIntervalThink()
    if IsServer() then
        -- Variables
        local target = self:GetParent()
        local flat_heal = self.inner_vitality_heal
        local attrib_bonus = self.inner_vitality_attrib_bonus
        local hurt_attrib_bonus = self.inner_vitality_hurt_attrib_bonus
        local hurt_perc = self.inner_vitality_hurt_percent
        local health_perc = target:GetHealthPercent()/100


        -- 0=strength
        -- 1=agility
        -- 2=intellegence
        local primary_attribute = target:GetPrimaryAttribute()
        local primary_attribute_value = 0

        -- getting the value of the primary attribute
        if primary_attribute == 0 then
            primary_attribute_value = target:GetStrength()
        elseif primary_attribute == 1 then
            primary_attribute_value = target:GetAgility()
        elseif primary_attribute == 2 then
            primary_attribute_value = target:GetIntellect()
        end


        local bonus_heal = 0

        -- calculate the bonus health depending on the targets health
        if health_perc <= hurt_perc then
            bonus_heal = primary_attribute_value * hurt_attrib_bonus   
        else
            bonus_heal = primary_attribute_value * attrib_bonus
        end


        local heal = (flat_heal + bonus_heal)

        if self.heal_amount and self.heal_amount ~= heal then
            self.heal_amount = heal
        end
    end
end

function modifier_inner_vitality:OnRefresh()
    self.inner_vitality_heal = self:GetAbility():GetSpecialValueFor( "heal" )
    self.inner_vitality_attrib_bonus = self:GetAbility():GetSpecialValueFor( "attrib_bonus" )
    self.inner_vitality_hurt_attrib_bonus = self:GetAbility():GetSpecialValueFor( "hurt_attrib_bonus" )
    self.inner_vitality_hurt_percent = self:GetAbility():GetSpecialValueFor("hurt_percent")

    if IsServer() then
        --print("Refreshed")
        self:GetParent():CalculateStatBonus()
    end
end

function modifier_inner_vitality:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
    }

    return funcs
end

function modifier_inner_vitality:GetModifierConstantHealthRegen( params)
    return self.heal_amount
end
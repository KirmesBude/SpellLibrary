LinkLuaModifier( "modifier_berserkers_blood" , "heroes/hero_huskar/modifiers/modifier_berserkers_blood.lua" , LUA_MODIFIER_MOTION_NONE )

--[[
    Author: Bude
    Date: 30.09.2015
    Simply applies the lua modifier
--]]
function ApplyLuaModifier( keys )
    local caster = keys.caster
    local ability = keys.ability
    local modifiername = keys.ModifierName

    caster:AddNewModifier(caster, ability, modifiername, {})
end
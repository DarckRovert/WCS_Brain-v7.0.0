--[[
    WCS_PetManager.lua - Pet Intelligence Engine v8.0.0 (Multi-Class)
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}
WCS.PetManager = WCS.PetManager or {}
local PM = WCS.PetManager

function PM:OnUpdate()
    -- Class guard: Pet AI only for Warlock and Hunter
    if WCS.ClassEngine then
        local cls = WCS.ClassEngine.class
        if cls and cls ~= "WARLOCK" and cls ~= "HUNTER" then return end
    end

    -- Integration with the new UI Config persistence
    if not WCS_BrainSaved or not WCS_BrainSaved.Config or not WCS_BrainSaved.Config.PetManager then return end
    if not UnitExists("pet") then return end
    
    -- [1] Basic Health Check
    local petMaxHP = UnitHealthMax("pet")
    if petMaxHP <= 0 then return end
    local hp = (UnitHealth("pet") / petMaxHP) * 100
    if hp < 40 and not UnitAffectingCombat("player") then
        WCS:Log("Pet HP bajo (" .. math.floor(hp) .. "%). Intentando curar...")
        if WCS.SpellManager then WCS.SpellManager:Cast("Health Funnel") end
    end
    
    -- [2] Aggro Management (Passive on low HP)
    if hp < 20 and UnitAffectingCombat("pet") then
        PetPassiveMode()
        PetFollow()
    end
    
    -- [3] Auto-Attack
    if UnitExists("target") and UnitCanAttack("player", "target") and not UnitAffectingCombat("pet") then
        PetAttack()
    end
end

WCS:Log("Pet Manager v8.0.0 (Multi-Class Guard) Ready.")

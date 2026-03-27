--[[
    WCS_PetManager.lua - Pet Intelligence Engine v9.3.0 (Multi-Class)
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}
WCS.PetManager = WCS.PetManager or {}
local PM = WCS.PetManager

function PM:OnUpdate()
    -- Solo para Brujos y Cazadores
    local cls = WCS.ClassEngine and WCS.ClassEngine.class
    if cls and cls ~= "WARLOCK" and cls ~= "HUNTER" then return end

    if not UnitExists("pet") then return end
    
    -- [1] DELEGACIÃ“N AL MOTOR AVANZADO (Si es Brujo)
    -- Esto garantiza que el PetAI tome el control total sin interferencias del manager bÃ¡sico
    if cls == "WARLOCK" and WCS_BrainPetAI and WCS_BrainPetAI.ENABLED then
        return -- Si PetAI estÃ¡ activo, Ã©l toma el control total
    end

    -- [2] LÃ³gica bÃ¡sica para Cazadores o si PetAI estÃ¡ apagado
    if not WCS_BrainSaved or not WCS_BrainSaved.Config or not WCS_BrainSaved.Config.PetManager then return end
    
    local petMaxHP = UnitHealthMax("pet")
    if petMaxHP <= 0 then return end
    local hp = (UnitHealth("pet") / petMaxHP) * 100
    
    -- CuraciÃ³n bÃ¡sica
    if hp < 40 and not UnitAffectingCombat("player") then
        if WCS.SpellManager then WCS.SpellManager:Cast("Health Funnel") end
    end
    
    -- Ataque bÃ¡sico
    if UnitExists("target") and UnitCanAttack("player", "target") and not UnitAffectingCombat("pet") then
        PetAttack()
    end
end

WCS:Log("Pet Manager v9.3.0 (Multi-Class Guard) Ready.")

-- WCS_BrainDashboard_Test.lua
-- Script de prueba para verificar que el Dashboard puede mostrar datos

-- Comando de prueba para simular datos
SlashCmdList["WCSDASHTEST"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("=== WCS Dashboard Test ===", 1, 1, 0)
    
    -- Simular eventos procesados
    if WCS_BrainEventThrottle and WCS_BrainEventThrottle.State then
        WCS_BrainEventThrottle.State.totalProcessed = (WCS_BrainEventThrottle.State.totalProcessed or 0) + 100
        WCS_BrainEventThrottle.State.totalBlocked = (WCS_BrainEventThrottle.State.totalBlocked or 0) + 50
        DEFAULT_CHAT_FRAME:AddMessage("Eventos simulados: +100 procesados, +50 bloqueados", 0, 1, 0)
    end
    
    -- Simular cooldowns
    if WCS_Brain and WCS_Brain.Cooldowns then
        WCS_Brain.Cooldowns["TestSpell1"] = GetTime() + 10
        WCS_Brain.Cooldowns["TestSpell2"] = GetTime() + 15
        WCS_Brain.Cooldowns["TestSpell3"] = GetTime() + 20
        DEFAULT_CHAT_FRAME:AddMessage("Cooldowns simulados: 3 habilidades", 0, 1, 0)
    end
    
    -- Simular pet cooldowns
    if WCS_BrainPetAI and WCS_BrainPetAI.cooldowns then
        WCS_BrainPetAI.cooldowns["PetAbility1"] = GetTime() + 8
        WCS_BrainPetAI.cooldowns["PetAbility2"] = GetTime() + 12
        DEFAULT_CHAT_FRAME:AddMessage("Pet Cooldowns simulados: 2 habilidades", 0, 1, 0)
    end
    
    -- Simular caché
    if WCS_BrainCache and WCS_BrainCache.Storage then
        WCS_BrainCache.Storage["TestData1"] = {value = 123}
        WCS_BrainCache.Storage["TestData2"] = {value = 456}
        WCS_BrainCache.Storage["TestData3"] = {value = 789}
        WCS_BrainCache.Storage["TestData4"] = {value = 999}
        DEFAULT_CHAT_FRAME:AddMessage("Caché simulado: 4 items", 0, 1, 0)
    end
    
    -- Simular decisiones de IA
    if WCS_Brain then
        WCS_Brain.totalDecisions = (WCS_Brain.totalDecisions or 0) + 25
        DEFAULT_CHAT_FRAME:AddMessage("Decisiones IA simuladas: +25", 0, 1, 0)
    end
    
    if WCS_BrainPetAI then
        WCS_BrainPetAI.totalDecisions = (WCS_BrainPetAI.totalDecisions or 0) + 15
        DEFAULT_CHAT_FRAME:AddMessage("Decisiones Pet IA simuladas: +15", 0, 1, 0)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("Datos de prueba agregados. Revisa el Dashboard.", 1, 1, 0)
end
SLASH_WCSDASHTEST1 = "/wcsdashtest"

DEFAULT_CHAT_FRAME:AddMessage("WCS Dashboard Test cargado. Usa /wcsdashtest para simular datos", 1, 1, 0)

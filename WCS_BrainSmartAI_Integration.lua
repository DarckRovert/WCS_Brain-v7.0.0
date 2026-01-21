-- WCS_BrainSmartAI_Integration.lua
-- Hook automático para integrar SmartAI con BrainAI
-- Este archivo se carga después de BrainAI y aplica el hook automáticamente

if not WCS_BrainAI or not WCS_BrainSmartAI then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[SmartAI Integration]|r Error: WCS_BrainAI o WCS_BrainSmartAI no encontrado")
    return
end

-- Guardar referencia a la función original
WCS_BrainAI.OriginalGetBestAction = WCS_BrainAI.GetBestAction

-- Hook mejorado que integra SmartAI
function WCS_BrainAI:GetBestAction()
    -- Llamar a la función original
    local best = self:OriginalGetBestAction()
    
    -- Si no hay decisión, retornar nil
    if not best then
        return nil
    end
    
    -- INTEGRACIÓN CON SMARTAI: Mejorar la decisión con análisis avanzado
    if WCS_BrainSmartAI then
        local enhancedDecision = WCS_BrainSmartAI:EnhanceDecision(best)
        if enhancedDecision then
            best = enhancedDecision
            if WCS_Brain and WCS_Brain.DEBUG then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[SmartAI]|r Decisión mejorada: " .. (best.spell or "?"))
            end
        end
    end
    
    return best
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[SmartAI Integration]|r Hook aplicado correctamente a WCS_BrainAI:GetBestAction()")

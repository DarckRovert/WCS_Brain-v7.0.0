-- WCS_BrainDashboard_Debug.lua
-- Script de depuración para el Dashboard
-- Verifica qué estructuras de datos existen y están disponibles

-- Comando de debug
SlashCmdList["WCSDEBUG"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("=== WCS Brain Dashboard Debug ===", 1, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
    
    -- 1. Verificar WCS_Brain
    if WCS_Brain then
        DEFAULT_CHAT_FRAME:AddMessage("✓ WCS_Brain existe", 0, 1, 0)
        
        -- Verificar Cooldowns
        if WCS_Brain.Cooldowns then
            local count = 0
            for _ in pairs(WCS_Brain.Cooldowns) do
                count = count + 1
            end
            DEFAULT_CHAT_FRAME:AddMessage("  ✓ WCS_Brain.Cooldowns existe (" .. count .. " items)", 0, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("  ✗ WCS_Brain.Cooldowns NO existe", 1, 0, 0)
        end
        
        -- Verificar PetAI
        if WCS_Brain.PetAI then
            DEFAULT_CHAT_FRAME:AddMessage("  ✓ WCS_Brain.PetAI existe", 0, 1, 0)
            if WCS_Brain.PetAI.cooldowns then
                local count = 0
                for _ in pairs(WCS_Brain.PetAI.cooldowns) do
                    count = count + 1
                end
                DEFAULT_CHAT_FRAME:AddMessage("    ✓ WCS_Brain.PetAI.cooldowns existe (" .. count .. " items)", 0, 1, 0)
            else
                DEFAULT_CHAT_FRAME:AddMessage("    ✗ WCS_Brain.PetAI.cooldowns NO existe", 1, 0, 0)
            end
            
            if WCS_Brain.PetAI.History then
                DEFAULT_CHAT_FRAME:AddMessage("    ✓ WCS_Brain.PetAI.History existe (" .. table.getn(WCS_Brain.PetAI.History) .. " items)", 0, 1, 0)
            else
                DEFAULT_CHAT_FRAME:AddMessage("    ✗ WCS_Brain.PetAI.History NO existe", 1, 0, 0)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("  ✗ WCS_Brain.PetAI NO existe", 1, 0, 0)
        end
        
        -- Verificar BrainAI
        if WCS_Brain.BrainAI then
            DEFAULT_CHAT_FRAME:AddMessage("  ✓ WCS_Brain.BrainAI existe", 0, 1, 0)
            if WCS_Brain.BrainAI.History then
                DEFAULT_CHAT_FRAME:AddMessage("    ✓ WCS_Brain.BrainAI.History existe (" .. table.getn(WCS_Brain.BrainAI.History) .. " items)", 0, 1, 0)
            else
                DEFAULT_CHAT_FRAME:AddMessage("    ✗ WCS_Brain.BrainAI.History NO existe", 1, 0, 0)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("  ✗ WCS_Brain.BrainAI NO existe", 1, 0, 0)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("✗ WCS_Brain NO existe", 1, 0, 0)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
    
    -- 2. Verificar WCS_BrainEventThrottle
    if WCS_BrainEventThrottle then
        DEFAULT_CHAT_FRAME:AddMessage("✓ WCS_BrainEventThrottle existe", 0, 1, 0)
        if WCS_BrainEventThrottle.State then
            DEFAULT_CHAT_FRAME:AddMessage("  ✓ WCS_BrainEventThrottle.State existe", 0, 1, 0)
            DEFAULT_CHAT_FRAME:AddMessage("    totalProcessed: " .. (WCS_BrainEventThrottle.State.totalProcessed or 0), 1, 1, 1)
            DEFAULT_CHAT_FRAME:AddMessage("    totalBlocked: " .. (WCS_BrainEventThrottle.State.totalBlocked or 0), 1, 1, 1)
        else
            DEFAULT_CHAT_FRAME:AddMessage("  ✗ WCS_BrainEventThrottle.State NO existe", 1, 0, 0)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("✗ WCS_BrainEventThrottle NO existe", 1, 0, 0)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
    
    -- 3. Verificar WCS_BrainCache
    if WCS_BrainCache then
        DEFAULT_CHAT_FRAME:AddMessage("✓ WCS_BrainCache existe", 0, 1, 0)
        if WCS_BrainCache.Storage then
            local count = 0
            for _ in pairs(WCS_BrainCache.Storage) do
                count = count + 1
            end
            DEFAULT_CHAT_FRAME:AddMessage("  ✓ WCS_BrainCache.Storage existe (" .. count .. " items)", 0, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("  ✗ WCS_BrainCache.Storage NO existe", 1, 0, 0)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("✗ WCS_BrainCache NO existe", 1, 0, 0)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
    
    -- 4. Verificar funciones de API de WoW
    DEFAULT_CHAT_FRAME:AddMessage("=== API de WoW ===", 1, 1, 0)
    
    if UpdateAddOnMemoryUsage then
        DEFAULT_CHAT_FRAME:AddMessage("✓ UpdateAddOnMemoryUsage existe", 0, 1, 0)
        UpdateAddOnMemoryUsage()
        local mem = GetAddOnMemoryUsage("WCS_Brain")
        DEFAULT_CHAT_FRAME:AddMessage("  Memoria WCS_Brain: " .. string.format("%.2f KB", mem or 0), 1, 1, 1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("✗ UpdateAddOnMemoryUsage NO existe (normal en WoW 1.12)", 1, 1, 0)
    end
    
    if GetFramerate then
        DEFAULT_CHAT_FRAME:AddMessage("✓ GetFramerate existe: " .. string.format("%.1f", GetFramerate()), 0, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("✗ GetFramerate NO existe", 1, 0, 0)
    end
    
    if GetNetStats then
        local _, _, latency = GetNetStats()
        DEFAULT_CHAT_FRAME:AddMessage("✓ GetNetStats existe: " .. (latency or 0) .. " ms", 0, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("✗ GetNetStats NO existe", 1, 0, 0)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("=== Fin del Debug ===", 1, 1, 0)
end
SLASH_WCSDEBUG1 = "/wcsdebug"

DEFAULT_CHAT_FRAME:AddMessage("WCS Dashboard Debug cargado. Usa /wcsdebug", 1, 1, 0)

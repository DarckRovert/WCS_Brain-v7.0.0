-- WCS_BrainDashboard_Inspect.lua
-- Inspecciona los valores actuales del Dashboard

SlashCmdList["WCSDASHINSPECT"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("=== WCS Dashboard Inspection ===", 1, 1, 0)
    
    if not WCS_Brain or not WCS_Brain.Dashboard then
        DEFAULT_CHAT_FRAME:AddMessage("ERROR: Dashboard no existe", 1, 0, 0)
        return
    end
    
    local Dashboard = WCS_Brain.Dashboard
    
    DEFAULT_CHAT_FRAME:AddMessage("Dashboard.metrics:", 1, 1, 0)
    if Dashboard.metrics then
        DEFAULT_CHAT_FRAME:AddMessage("  fps: " .. tostring(Dashboard.metrics.fps), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  latency: " .. tostring(Dashboard.metrics.latency), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  memoryUsage: " .. tostring(Dashboard.metrics.memoryUsage), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  cpuUsage: " .. tostring(Dashboard.metrics.cpuUsage), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  eventsProcessed: " .. tostring(Dashboard.metrics.eventsProcessed), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  eventsThrottled: " .. tostring(Dashboard.metrics.eventsThrottled), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  cooldownsActive: " .. tostring(Dashboard.metrics.cooldownsActive), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  petCooldownsActive: " .. tostring(Dashboard.metrics.petCooldownsActive), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  cacheSize: " .. tostring(Dashboard.metrics.cacheSize), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  aiDecisions: " .. tostring(Dashboard.metrics.aiDecisions), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  petAIDecisions: " .. tostring(Dashboard.metrics.petAIDecisions), 1, 1, 1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("  ERROR: metrics no existe", 1, 0, 0)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Fuentes de datos:", 1, 1, 0)
    
    -- EventThrottle
    if WCS_BrainEventThrottle and WCS_BrainEventThrottle.State then
        DEFAULT_CHAT_FRAME:AddMessage("  EventThrottle.State.totalProcessed: " .. tostring(WCS_BrainEventThrottle.State.totalProcessed), 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("  EventThrottle.State.totalBlocked: " .. tostring(WCS_BrainEventThrottle.State.totalBlocked), 0, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("  EventThrottle.State: NO EXISTE", 1, 0, 0)
    end
    
    -- Cooldowns
    if WCS_Brain.Cooldowns then
        local count = 0
        for _ in pairs(WCS_Brain.Cooldowns) do count = count + 1 end
        DEFAULT_CHAT_FRAME:AddMessage("  WCS_Brain.Cooldowns: " .. count .. " items", 0, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("  WCS_Brain.Cooldowns: NO EXISTE", 1, 0, 0)
    end
    
    -- Pet Cooldowns
    if WCS_BrainPetAI and WCS_BrainPetAI.cooldowns then
        local count = 0
        for _ in pairs(WCS_BrainPetAI.cooldowns) do count = count + 1 end
        DEFAULT_CHAT_FRAME:AddMessage("  WCS_BrainPetAI.cooldowns: " .. count .. " items", 0, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("  WCS_BrainPetAI.cooldowns: NO EXISTE", 1, 0, 0)
    end
    
    -- Cache
    if WCS_BrainCache and WCS_BrainCache.Storage then
        local count = 0
        for _ in pairs(WCS_BrainCache.Storage) do count = count + 1 end
        DEFAULT_CHAT_FRAME:AddMessage("  WCS_BrainCache.Storage: " .. count .. " items", 0, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("  WCS_BrainCache.Storage: NO EXISTE", 1, 0, 0)
    end
    
    -- AI Decisions
    if WCS_Brain.totalDecisions then
        DEFAULT_CHAT_FRAME:AddMessage("  WCS_Brain.totalDecisions: " .. tostring(WCS_Brain.totalDecisions), 0, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("  WCS_Brain.totalDecisions: NO EXISTE", 1, 0, 0)
    end
    
    if WCS_BrainPetAI and WCS_BrainPetAI.totalDecisions then
        DEFAULT_CHAT_FRAME:AddMessage("  WCS_BrainPetAI.totalDecisions: " .. tostring(WCS_BrainPetAI.totalDecisions), 0, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("  WCS_BrainPetAI.totalDecisions: NO EXISTE", 1, 0, 0)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("=== Fin Inspection ===", 1, 1, 0)
end
SLASH_WCSDASHINSPECT1 = "/wcsdashinspect"

DEFAULT_CHAT_FRAME:AddMessage("WCS Dashboard Inspect cargado. Usa /wcsdashinspect", 1, 1, 0)

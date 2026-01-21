--[[
    WCS_BrainSafety.lua - Sistema de Límites de Seguridad Globales
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.0.0
    
    Previene crashes y lag extremo mediante límites de seguridad
    y limpieza automática cuando se exceden.
]]--

WCS_BrainSafety = WCS_BrainSafety or {}
local Safety = WCS_BrainSafety

Safety.VERSION = "1.0.0"
Safety.enabled = true

-- ============================================================================
-- LÍMITES DE SEGURIDAD
-- ============================================================================
Safety.Limits = {
    -- Cachés y tablas
    maxCacheSize = 1000,
    maxCooldownEntries = 100,
    maxLearnedSpells = 500,
    maxLogEntries = 500,
    maxHistoryEntries = 200,
    
    -- Iteraciones y loops
    maxIterationsPerFrame = 100,
    maxRecursionDepth = 10,
    
    -- Memoria (estimado)
    maxMemoryMB = 50,
    
    -- Throttling
    maxEventsPerSecond = 100
}

-- ============================================================================
-- ESTADÍSTICAS
-- ============================================================================
Safety.Stats = {
    violations = 0,
    cleanups = 0,
    lastCheck = 0,
    
    -- Contadores por tipo
    violationsByType = {},
    cleanupsByType = {}
}

-- ============================================================================
-- VERIFICACIÓN DE LÍMITES
-- ============================================================================

function Safety:CheckAll()
    if not self.enabled then return true end
    
    local violations = {}
    local now = GetTime()
    
    -- Verificar cooldowns de WCS_Brain
    if WCS_Brain and WCS_Brain.Cooldowns then
        local count = self:CountTable(WCS_Brain.Cooldowns)
        if count > self.Limits.maxCooldownEntries then
            table.insert(violations, {
                type = "Cooldowns",
                count = count,
                limit = self.Limits.maxCooldownEntries,
                action = "cleanup"
            })
        end
    end
    
    -- Verificar cooldowns de PetAI
    if PetAI and PetAI.cooldowns then
        local count = self:CountTable(PetAI.cooldowns)
        if count > self.Limits.maxCooldownEntries then
            table.insert(violations, {
                type = "PetCooldowns",
                count = count,
                limit = self.Limits.maxCooldownEntries,
                action = "cleanup"
            })
        end
    end
    
    -- Verificar LearnedSpells
    if WCS_Brain and WCS_Brain.LearnedSpells then
        local count = self:CountTable(WCS_Brain.LearnedSpells)
        if count > self.Limits.maxLearnedSpells then
            table.insert(violations, {
                type = "LearnedSpells",
                count = count,
                limit = self.Limits.maxLearnedSpells,
                action = "warning"
            })
        end
    end
    
    -- Verificar logs
    if WCS_BrainLogger and WCS_BrainLogger.logs then
        local count = table.getn(WCS_BrainLogger.logs)
        if count > self.Limits.maxLogEntries then
            table.insert(violations, {
                type = "Logs",
                count = count,
                limit = self.Limits.maxLogEntries,
                action = "cleanup"
            })
        end
    end
    
    -- Verificar historial de notificaciones
    if WCS_BrainNotifications and WCS_BrainNotifications.State.history then
        local count = table.getn(WCS_BrainNotifications.State.history)
        if count > self.Limits.maxHistoryEntries then
            table.insert(violations, {
                type = "NotificationHistory",
                count = count,
                limit = self.Limits.maxHistoryEntries,
                action = "cleanup"
            })
        end
    end
    
    -- Procesar violaciones
    if table.getn(violations) > 0 then
        self:HandleViolations(violations)
        return false
    end
    
    self.Stats.lastCheck = now
    return true
end

function Safety:HandleViolations(violations)
    for i = 1, table.getn(violations) do
        local v = violations[i]
        
        -- Registrar violación
        self.Stats.violations = self.Stats.violations + 1
        self.Stats.violationsByType[v.type] = (self.Stats.violationsByType[v.type] or 0) + 1
        
        -- Ejecutar acción
        if v.action == "cleanup" then
            self:CleanupByType(v.type)
        elseif v.action == "warning" then
            if WCS_BrainNotifications then
                WCS_BrainNotifications:Warning(v.type .. " excedió límite: " .. v.count .. "/" .. v.limit)
            end
        end
    end
end

function Safety:CleanupByType(type)
    if type == "Cooldowns" and WCS_Brain and WCS_Brain.CleanupCooldowns then
        WCS_Brain:CleanupCooldowns()
        self.Stats.cleanups = self.Stats.cleanups + 1
        self.Stats.cleanupsByType[type] = (self.Stats.cleanupsByType[type] or 0) + 1
        
    elseif type == "PetCooldowns" and PetAI and PetAI.CleanupCooldowns then
        PetAI:CleanupCooldowns()
        self.Stats.cleanups = self.Stats.cleanups + 1
        self.Stats.cleanupsByType[type] = (self.Stats.cleanupsByType[type] or 0) + 1
        
    elseif type == "Logs" and WCS_BrainLogger and WCS_BrainLogger.logs then
        -- Mantener solo los últimos 250
        local logs = WCS_BrainLogger.logs
        local count = table.getn(logs)
        local toRemove = count - 250
        
        for i = 1, toRemove do
            table.remove(logs, 1)
        end
        
        self.Stats.cleanups = self.Stats.cleanups + 1
        self.Stats.cleanupsByType[type] = (self.Stats.cleanupsByType[type] or 0) + 1
        
    elseif type == "NotificationHistory" and WCS_BrainNotifications then
        -- Mantener solo los últimos 100
        local history = WCS_BrainNotifications.State.history
        local count = table.getn(history)
        local toRemove = count - 100
        
        for i = 1, toRemove do
            table.remove(history, 1)
        end
        
        self.Stats.cleanups = self.Stats.cleanups + 1
        self.Stats.cleanupsByType[type] = (self.Stats.cleanupsByType[type] or 0) + 1
    end
end

-- ============================================================================
-- UTILIDADES
-- ============================================================================

function Safety:CountTable(t)
    if not t then return 0 end
    
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    
    return count
end

function Safety:GetStats()
    return {
        violations = self.Stats.violations,
        cleanups = self.Stats.cleanups,
        lastCheck = self.Stats.lastCheck,
        violationsByType = self.Stats.violationsByType,
        cleanupsByType = self.Stats.cleanupsByType
    }
end

function Safety:ResetStats()
    self.Stats.violations = 0
    self.Stats.cleanups = 0
    self.Stats.violationsByType = {}
    self.Stats.cleanupsByType = {}
end

function Safety:Enable()
    self.enabled = true
end

function Safety:Disable()
    self.enabled = false
end

function Safety:SetLimit(limitName, value)
    if self.Limits[limitName] and type(value) == "number" and value > 0 then
        self.Limits[limitName] = value
        return true
    end
    return false
end

-- ============================================================================
-- FRAME DE VERIFICACIÓN PERIÓDICA
-- ============================================================================
local SafetyFrame = CreateFrame("Frame")
SafetyFrame.elapsed = 0
SafetyFrame:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    
    -- Verificar cada 30 segundos
    if this.elapsed >= 30 then
        this.elapsed = 0
        Safety:CheckAll()
    end
end)

-- ============================================================================
-- COMANDOS SLASH
-- ============================================================================
SLASH_WCSSAFETY1 = "/wcssafety"
SlashCmdList["WCSSAFETY"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "check" or msg == "" then
        local success = Safety:CheckAll()
        
        if success then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Safety]|r Todos los límites OK")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[WCS Safety]|r Violaciones detectadas y corregidas")
        end
        
    elseif msg == "stats" then
        local stats = Safety:GetStats()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Safety]|r Estadísticas:")
        DEFAULT_CHAT_FRAME:AddMessage("  Violaciones: " .. stats.violations)
        DEFAULT_CHAT_FRAME:AddMessage("  Limpiezas: " .. stats.cleanups)
        
        if Safety:CountTable(stats.violationsByType) > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("  Violaciones por tipo:")
            for type, count in pairs(stats.violationsByType) do
                DEFAULT_CHAT_FRAME:AddMessage("    " .. type .. ": " .. count)
            end
        end
        
    elseif msg == "reset" then
        Safety:ResetStats()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Safety]|r Estadísticas reseteadas")
        
    elseif msg == "limits" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Safety]|r Límites configurados:")
        DEFAULT_CHAT_FRAME:AddMessage("  maxCooldownEntries: " .. Safety.Limits.maxCooldownEntries)
        DEFAULT_CHAT_FRAME:AddMessage("  maxLearnedSpells: " .. Safety.Limits.maxLearnedSpells)
        DEFAULT_CHAT_FRAME:AddMessage("  maxLogEntries: " .. Safety.Limits.maxLogEntries)
        DEFAULT_CHAT_FRAME:AddMessage("  maxHistoryEntries: " .. Safety.Limits.maxHistoryEntries)
        
    elseif msg == "enable" or msg == "on" then
        Safety:Enable()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Safety]|r Activado")
        
    elseif msg == "disable" or msg == "off" then
        Safety:Disable()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Safety]|r Desactivado")
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Safety]|r Comandos disponibles:")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcssafety check - Verificar límites")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcssafety stats - Ver estadísticas")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcssafety limits - Ver límites")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcssafety reset - Resetear estadísticas")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcssafety enable - Activar")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcssafety disable - Desactivar")
    end
end

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================
DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Brain]|r Safety v" .. Safety.VERSION .. " cargado")

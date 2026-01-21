--[[
    WCS_BrainEventThrottle.lua - Sistema de Throttling de Eventos
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.0.0
    
    Reduce la carga de CPU limitando la frecuencia de procesamiento de eventos
    que se disparan muy frecuentemente durante el combate.
]]--

WCS_BrainEventThrottle = WCS_BrainEventThrottle or {}
local Throttle = WCS_BrainEventThrottle

Throttle.VERSION = "1.0.0"
Throttle.enabled = true

-- ============================================================================
-- CONFIGURACIÓN DE INTERVALOS
-- ============================================================================
Throttle.Intervals = {
    -- Eventos de combate (muy frecuentes)
    COMBAT_LOG = 0.1,           -- Max 10 veces/segundo
    PLAYER_REGEN_DISABLED = 0.2, -- Max 5 veces/segundo
    PLAYER_REGEN_ENABLED = 0.2,
    
    -- Eventos de unidades
    UNIT_HEALTH = 0.15,         -- Max ~6.7 veces/segundo
    UNIT_POWER = 0.15,
    UNIT_MANA = 0.15,
    UNIT_AURA = 0.2,            -- Max 5 veces/segundo
    
    -- Eventos de mascota
    UNIT_PET = 0.15,
    PET_ATTACK_START = 0.1,
    PET_ATTACK_STOP = 0.1,
    PET_BAR_UPDATE = 0.2,
    
    -- Eventos de target
    PLAYER_TARGET_CHANGED = 0.05, -- Más frecuente, es importante
    
    -- Eventos de spell
    SPELLCAST_START = 0.05,
    SPELLCAST_STOP = 0.05,
    SPELLCAST_FAILED = 0.1,
    SPELLCAST_INTERRUPTED = 0.1,
    
    -- Eventos de UI
    ACTIONBAR_UPDATE = 0.3,     -- Max ~3 veces/segundo
    UPDATE_SHAPESHIFT_FORM = 0.3,
    
    -- Eventos de grupo/raid
    PARTY_MEMBERS_CHANGED = 0.5,
    RAID_ROSTER_UPDATE = 0.5,
    
    -- Default para eventos no especificados
    DEFAULT = 0.1
}

-- ============================================================================
-- ESTADO DE THROTTLING
-- ============================================================================
Throttle.State = {
    lastUpdate = {},      -- Último tiempo de procesamiento por evento
    blockedCount = {},    -- Contador de eventos bloqueados
    totalBlocked = 0,     -- Total de eventos bloqueados
    totalProcessed = 0    -- Total de eventos procesados
}

-- ============================================================================
-- FUNCIONES PRINCIPALES
-- ============================================================================

-- Verificar si un evento debe ser procesado
function Throttle:ShouldProcess(eventName)
    if not self.enabled then
        return true
    end
    
    local now = GetTime()
    local last = self.State.lastUpdate[eventName] or 0
    local interval = self.Intervals[eventName] or self.Intervals.DEFAULT
    
    if now - last >= interval then
        self.State.lastUpdate[eventName] = now
        self.State.totalProcessed = self.State.totalProcessed + 1
        return true
    else
        -- Evento bloqueado por throttling
        self.State.blockedCount[eventName] = (self.State.blockedCount[eventName] or 0) + 1
        self.State.totalBlocked = self.State.totalBlocked + 1
        return false
    end
end

-- Forzar procesamiento de un evento (bypass throttling)
function Throttle:ForceProcess(eventName)
    local now = GetTime()
    self.State.lastUpdate[eventName] = now
    self.State.totalProcessed = self.State.totalProcessed + 1
end

-- Resetear throttling de un evento específico
function Throttle:Reset(eventName)
    if eventName then
        self.State.lastUpdate[eventName] = 0
        self.State.blockedCount[eventName] = 0
    else
        -- Resetear todo
        self.State.lastUpdate = {}
        self.State.blockedCount = {}
        self.State.totalBlocked = 0
        self.State.totalProcessed = 0
    end
end

-- Obtener estadísticas de throttling
function Throttle:GetStats()
    local stats = {
        totalProcessed = self.State.totalProcessed,
        totalBlocked = self.State.totalBlocked,
        blockRate = 0,
        topBlocked = {}
    }
    
    -- Calcular tasa de bloqueo
    local total = stats.totalProcessed + stats.totalBlocked
    if total > 0 then
        stats.blockRate = (stats.totalBlocked / total) * 100
    end
    
    -- Top 5 eventos más bloqueados
    local sorted = {}
    for event, count in pairs(self.State.blockedCount) do
        table.insert(sorted, {event = event, count = count})
    end
    
    -- Ordenar por count (bubble sort para Lua 5.0)
    for i = 1, table.getn(sorted) do
        for j = i + 1, table.getn(sorted) do
            if sorted[j].count > sorted[i].count then
                local temp = sorted[i]
                sorted[i] = sorted[j]
                sorted[j] = temp
            end
        end
    end
    
    -- Top 5
    for i = 1, math.min(5, table.getn(sorted)) do
        table.insert(stats.topBlocked, sorted[i])
    end
    
    return stats
end

-- Configurar intervalo personalizado
function Throttle:SetInterval(eventName, interval)
    if type(interval) == "number" and interval >= 0 then
        self.Intervals[eventName] = interval
        return true
    end
    return false
end

-- Habilitar/deshabilitar throttling
function Throttle:Enable()
    self.enabled = true
end

function Throttle:Disable()
    self.enabled = false
end

function Throttle:Toggle()
    self.enabled = not self.enabled
    return self.enabled
end

-- ============================================================================
-- COMANDOS SLASH
-- ============================================================================
SLASH_WCSTHROTTLE1 = "/wcsthrottle"
SlashCmdList["WCSTHROTTLE"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "stats" or msg == "status" then
        local stats = Throttle:GetStats()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Throttle]|r Estadísticas:")
        DEFAULT_CHAT_FRAME:AddMessage("  Procesados: " .. stats.totalProcessed)
        DEFAULT_CHAT_FRAME:AddMessage("  Bloqueados: " .. stats.totalBlocked)
        DEFAULT_CHAT_FRAME:AddMessage("  Tasa de bloqueo: " .. string.format("%.1f%%", stats.blockRate))
        
        if table.getn(stats.topBlocked) > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("  Top eventos bloqueados:")
            for i = 1, table.getn(stats.topBlocked) do
                local item = stats.topBlocked[i]
                DEFAULT_CHAT_FRAME:AddMessage("    " .. i .. ". " .. item.event .. ": " .. item.count)
            end
        end
        
    elseif msg == "reset" then
        Throttle:Reset()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Throttle]|r Estadísticas reseteadas")
        
    elseif msg == "enable" or msg == "on" then
        Throttle:Enable()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Throttle]|r Activado")
        
    elseif msg == "disable" or msg == "off" then
        Throttle:Disable()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Throttle]|r Desactivado")
        
    elseif msg == "toggle" then
        local enabled = Throttle:Toggle()
        local status = enabled and "Activado" or "Desactivado"
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Throttle]|r " .. status)
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Throttle]|r Comandos disponibles:")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsthrottle stats - Ver estadísticas")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsthrottle reset - Resetear estadísticas")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsthrottle enable - Activar throttling")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsthrottle disable - Desactivar throttling")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsthrottle toggle - Alternar estado")
    end
end

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================
DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Brain]|r EventThrottle v" .. Throttle.VERSION .. " cargado")

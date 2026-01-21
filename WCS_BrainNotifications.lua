--[[
    WCS_BrainNotifications.lua - Sistema de Notificaciones en Pantalla
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.0.0
    
    Sistema de notificaciones visuales estilo Blizzard para feedback
    inmediato al usuario sin saturar el chat.
]]--

WCS_BrainNotifications = WCS_BrainNotifications or {}
local Notifications = WCS_BrainNotifications

Notifications.VERSION = "1.0.0"
Notifications.enabled = true

-- ============================================================================
-- TIPOS DE NOTIFICACIÓN Y COLORES
-- ============================================================================
Notifications.Types = {
    INFO = {
        r = 1.0, g = 1.0, b = 1.0,  -- Blanco
        sound = nil
    },
    SUCCESS = {
        r = 0.0, g = 1.0, b = 0.0,  -- Verde
        sound = "AuctionWindowOpen"
    },
    WARNING = {
        r = 1.0, g = 0.8, b = 0.0,  -- Amarillo/Naranja
        sound = "RaidWarning"
    },
    ERROR = {
        r = 1.0, g = 0.0, b = 0.0,  -- Rojo
        sound = "igQuestFailed"
    },
    CRITICAL = {
        r = 1.0, g = 0.0, b = 1.0,  -- Magenta
        sound = "RaidBossWarning"
    }
}

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================
Notifications.Config = {
    -- Usar UIErrorsFrame (centro de pantalla)
    useUIErrorsFrame = true,
    
    -- Usar chat como fallback
    useChatFallback = true,
    
    -- Reproducir sonidos
    playSounds = true,
    
    -- Duración de notificaciones (segundos)
    duration = 3.0,
    
    -- Throttling de notificaciones idénticas
    throttleTime = 2.0,
    
    -- Prefijo para mensajes
    prefix = "|cFF9482C9[WCS Brain]|r "
}

-- ============================================================================
-- ESTADO
-- ============================================================================
Notifications.State = {
    lastMessages = {},  -- Últimos mensajes para throttling
    messageCount = 0,   -- Contador de mensajes
    history = {}        -- Historial de notificaciones
}

-- ============================================================================
-- FUNCIONES PRINCIPALES
-- ============================================================================

-- Mostrar notificación
function Notifications:Show(message, notifType, skipThrottle)
    if not self.enabled then return end
    if not message or message == "" then return end
    
    notifType = notifType or "INFO"
    local typeData = self.Types[notifType] or self.Types.INFO
    
    -- Throttling de mensajes idénticos
    if not skipThrottle then
        local now = GetTime()
        local lastTime = self.State.lastMessages[message] or 0
        
        if now - lastTime < self.Config.throttleTime then
            -- Mensaje duplicado muy reciente, ignorar
            return
        end
        
        self.State.lastMessages[message] = now
    end
    
    -- Mostrar en UIErrorsFrame (centro de pantalla)
    if self.Config.useUIErrorsFrame and UIErrorsFrame then
        UIErrorsFrame:AddMessage(
            message,
            typeData.r,
            typeData.g,
            typeData.b,
            1.0,
            UIERRORS_HOLD_TIME or self.Config.duration
        )
    end
    
    -- Fallback a chat si está habilitado
    if self.Config.useChatFallback then
        local colorCode = string.format("|cFF%02X%02X%02X", 
            typeData.r * 255, 
            typeData.g * 255, 
            typeData.b * 255
        )
        DEFAULT_CHAT_FRAME:AddMessage(
            self.Config.prefix .. colorCode .. message .. "|r"
        )
    end
    
    -- Reproducir sonido
    if self.Config.playSounds and typeData.sound then
        PlaySound(typeData.sound)
    end
    
    -- Guardar en historial
    self:AddToHistory(message, notifType)
end

-- Mostrar con sonido personalizado
function Notifications:ShowWithSound(message, notifType, soundFile)
    self:Show(message, notifType)
    
    if self.Config.playSounds and soundFile then
        PlaySound(soundFile)
    end
end

-- Mostrar notificación de éxito
function Notifications:Success(message)
    self:Show(message, "SUCCESS")
end

-- Mostrar advertencia
function Notifications:Warning(message)
    self:Show(message, "WARNING")
end

-- Mostrar error
function Notifications:Error(message)
    self:Show(message, "ERROR")
end

-- Mostrar crítico
function Notifications:Critical(message)
    self:Show(message, "CRITICAL")
end

-- Mostrar info
function Notifications:Info(message)
    self:Show(message, "INFO")
end

-- ============================================================================
-- NOTIFICACIONES ESPECÍFICAS DEL ADDON
-- ============================================================================

-- IA
function Notifications:AIModeChanged(mode)
    local modeNames = {
        hybrid = "Híbrido",
        dqn_only = "DQN",
        smartai_only = "SmartAI",
        heuristic_only = "Heurístico"
    }
    local modeName = modeNames[mode] or mode
    self:Info("Modo de IA: " .. modeName)
end

function Notifications:AIEnabled()
    self:Success("IA Activada")
end

function Notifications:AIDisabled()
    self:Warning("IA Desactivada")
end

-- Mascota
function Notifications:PetSummoned(petName)
    self:Success(petName .. " invocado")
end

function Notifications:PetDismissed()
    self:Info("Mascota despedida")
end

function Notifications:PetDied()
    self:Error("¡Mascota muerta!")
end

function Notifications:PetLowHealth(percent)
    self:Warning(string.format("Mascota baja salud: %d%%", percent))
end

-- Combate
function Notifications:CombatStarted()
    self:Info("Combate iniciado")
end

function Notifications:CombatEnded()
    self:Info("Combate terminado")
end

function Notifications:LowHealth(percent)
    self:Critical(string.format("¡SALUD CRÍTICA: %d%%!", percent))
end

function Notifications:LowMana(percent)
    self:Warning(string.format("Maná bajo: %d%%", percent))
end

-- Cooldowns
function Notifications:CooldownReady(spellName)
    self:Success(spellName .. " disponible")
end

function Notifications:CooldownsCleanedUp(count)
    if count > 0 then
        self:Info(string.format("Limpieza: %d cooldowns expirados", count))
    end
end

-- Perfiles
function Notifications:ProfileChanged(profileName)
    self:Info("Perfil: " .. profileName)
end

function Notifications:ProfileSaved(profileName)
    self:Success("Perfil guardado: " .. profileName)
end

-- Sistema
function Notifications:AddonLoaded()
    self:Success("WCS Brain v" .. (WCS_Brain and WCS_Brain.VERSION or "?") .. " cargado")
end

function Notifications:MemoryWarning(usage)
    self:Warning(string.format("Uso de memoria alto: %d MB", usage))
end

function Notifications:ErrorOccurred(errorMsg)
    self:Error("Error: " .. errorMsg)
end

-- Integraciones
function Notifications:BossPhaseDetected(phase)
    self:Warning(string.format("Fase %d detectada", phase))
end

function Notifications:WeakAurasConnected()
    self:Success("WeakAuras conectado")
end

-- ============================================================================
-- HISTORIAL
-- ============================================================================

function Notifications:AddToHistory(message, notifType)
    local entry = {
        message = message,
        type = notifType,
        timestamp = GetTime(),
        time = date("%H:%M:%S")
    }
    
    table.insert(self.State.history, entry)
    self.State.messageCount = self.State.messageCount + 1
    
    -- Limitar historial a 100 entradas
    if table.getn(self.State.history) > 100 then
        table.remove(self.State.history, 1)
    end
end

function Notifications:GetHistory(count)
    count = count or 10
    local history = {}
    local total = table.getn(self.State.history)
    local start = math.max(1, total - count + 1)
    
    for i = start, total do
        table.insert(history, self.State.history[i])
    end
    
    return history
end

function Notifications:ClearHistory()
    self.State.history = {}
    self.State.messageCount = 0
end

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================

function Notifications:Enable()
    self.enabled = true
end

function Notifications:Disable()
    self.enabled = false
end

function Notifications:Toggle()
    self.enabled = not self.enabled
    return self.enabled
end

function Notifications:SetSoundsEnabled(enabled)
    self.Config.playSounds = enabled
end

function Notifications:SetChatFallback(enabled)
    self.Config.useChatFallback = enabled
end

function Notifications:SetThrottleTime(seconds)
    if type(seconds) == "number" and seconds >= 0 then
        self.Config.throttleTime = seconds
        return true
    end
    return false
end

-- ============================================================================
-- COMANDOS SLASH
-- ============================================================================
SLASH_WCSNOTIF1 = "/wcsnotif"
SlashCmdList["WCSNOTIF"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "test" then
        Notifications:Info("Notificación de prueba - INFO")
        Notifications:Success("Notificación de prueba - SUCCESS")
        Notifications:Warning("Notificación de prueba - WARNING")
        Notifications:Error("Notificación de prueba - ERROR")
        
    elseif msg == "history" then
        local history = Notifications:GetHistory(10)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Notif]|r Últimas 10 notificaciones:")
        for i = 1, table.getn(history) do
            local entry = history[i]
            DEFAULT_CHAT_FRAME:AddMessage("  [" .. entry.time .. "] " .. entry.type .. ": " .. entry.message)
        end
        
    elseif msg == "clear" then
        Notifications:ClearHistory()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Notif]|r Historial limpiado")
        
    elseif msg == "enable" or msg == "on" then
        Notifications:Enable()
        Notifications:Success("Notificaciones activadas")
        
    elseif msg == "disable" or msg == "off" then
        Notifications:Disable()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Notif]|r Notificaciones desactivadas")
        
    elseif msg == "toggle" then
        local enabled = Notifications:Toggle()
        local status = enabled and "activadas" or "desactivadas"
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Notif]|r Notificaciones " .. status)
        
    elseif string.find(msg, "sound") then
        if string.find(msg, "on") then
            Notifications:SetSoundsEnabled(true)
            Notifications:Success("Sonidos activados")
        elseif string.find(msg, "off") then
            Notifications:SetSoundsEnabled(false)
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Notif]|r Sonidos desactivados")
        end
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Notif]|r Comandos disponibles:")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsnotif test - Probar notificaciones")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsnotif history - Ver historial")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsnotif clear - Limpiar historial")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsnotif enable - Activar notificaciones")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsnotif disable - Desactivar notificaciones")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsnotif toggle - Alternar estado")
        DEFAULT_CHAT_FRAME:AddMessage("  /wcsnotif sound on/off - Sonidos")
    end
end

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================
DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Brain]|r Notifications v" .. Notifications.VERSION .. " cargado")

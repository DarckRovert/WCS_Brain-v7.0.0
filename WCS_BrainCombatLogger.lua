--[[
    WCS_BrainCombatLogger.lua - Sistema de Captura de Eventos de Combate
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.0.0
    
    Este archivo captura eventos del combat log y los envía a WCS_BrainMetrics
    para que el sistema de aprendizaje pueda analizar el rendimiento.
]]--

WCS_BrainCombatLogger = WCS_BrainCombatLogger or {}
local Logger = WCS_BrainCombatLogger

Logger.VERSION = "1.0.0"
Logger.enabled = true

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================
Logger.Config = {
    debugMode = false
}

-- ============================================================================
-- TRACKING DE COMBATE ACTUAL
-- ============================================================================
Logger.CurrentCombat = {
    active = false,
    spellsCast = {},  -- { [spellName] = { casts = 0, damage = 0, castTime = 0, lastCast = 0 } }
    lastSpellCast = nil,
    lastCastTime = 0
}

-- ============================================================================
-- FUNCIONES DE UTILIDAD
-- ============================================================================
local function debugPrint(msg)
    if Logger.Config.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[CombatLogger]|r " .. tostring(msg))
    end
end

local function getTime()
    return GetTime and GetTime() or 0
end

-- ============================================================================
-- PROCESAMIENTO DE EVENTOS DE COMBAT LOG
-- ============================================================================

-- Procesar evento de daño de hechizo
function Logger:ProcessSpellDamage(spellName, damage)
    if not self.CurrentCombat.active then return end
    if not spellName or not damage then return end
    
    -- Registrar en WCS_BrainMetrics si está disponible
    if WCS_BrainMetrics and WCS_BrainMetrics.RecordSpellDamage then
        -- Estimar cast time basado en el tiempo desde el último cast
        local now = getTime()
        local castTime = 0
        
        if self.CurrentCombat.lastSpellCast == spellName then
            castTime = now - self.CurrentCombat.lastCastTime
        else
            -- Usar tiempos de cast conocidos para hechizos comunes
            castTime = self:GetSpellCastTime(spellName)
        end
        
        WCS_BrainMetrics:RecordSpellDamage(spellName, damage, castTime)
        debugPrint("Daño registrado: " .. spellName .. " = " .. damage .. " (" .. string.format("%.2f", castTime) .. "s)")
    end
end

-- Procesar evento de cast de hechizo
function Logger:ProcessSpellCast(spellName)
    if not self.CurrentCombat.active then return end
    if not spellName then return end
    
    local now = getTime()
    self.CurrentCombat.lastSpellCast = spellName
    self.CurrentCombat.lastCastTime = now
    
    debugPrint("Hechizo casteado: " .. spellName)
end

-- Procesar uso de mana
function Logger:ProcessManaUsage(amount, spellName)
    if not self.CurrentCombat.active then return end
    if not amount then return end
    
    -- Registrar en WCS_BrainMetrics
    if WCS_BrainMetrics and WCS_BrainMetrics.RecordManaUsage then
        WCS_BrainMetrics:RecordManaUsage(amount, spellName)
        debugPrint("Mana usado: " .. amount .. " (" .. (spellName or "Unknown") .. ")")
    end
end

-- Obtener tiempo de cast estimado para hechizos conocidos
function Logger:GetSpellCastTime(spellName)
    -- Tiempos de cast comunes para Warlock (en segundos)
    local castTimes = {
        -- Hechizos de daño directo
        ["Shadow Bolt"] = 3.0,
        ["Immolate"] = 2.0,
        ["Searing Pain"] = 1.5,
        ["Soul Fire"] = 6.0,
        
        -- DoTs (instant)
        ["Corruption"] = 0,
        ["Curse of Agony"] = 0,
        ["Curse of Doom"] = 0,
        ["Curse of the Elements"] = 0,
        ["Curse of Recklessness"] = 0,
        ["Curse of Weakness"] = 0,
        ["Curse of Tongues"] = 0,
        
        -- AoE
        ["Rain of Fire"] = 0,  -- Channeled, pero instant cast
        ["Hellfire"] = 0,      -- Channeled
        
        -- Utility
        ["Life Tap"] = 0,
        ["Dark Pact"] = 0,
        ["Death Coil"] = 0,
        ["Howl of Terror"] = 0,
        ["Fear"] = 1.5,
        ["Banish"] = 1.5,
        
        -- Drain spells (channeled)
        ["Drain Life"] = 0,
        ["Drain Soul"] = 0,
        ["Drain Mana"] = 0,
        
        -- Pet
        ["Health Funnel"] = 0
    }
    
    return castTimes[spellName] or 1.5  -- Default 1.5s si no se conoce
end

-- ============================================================================
-- MANEJO DE EVENTOS
-- ============================================================================

function Logger:OnCombatStart()
    self.CurrentCombat.active = true
    self.CurrentCombat.spellsCast = {}
    self.CurrentCombat.lastSpellCast = nil
    self.CurrentCombat.lastCastTime = 0
    
    -- Activar combate en WCS_BrainMetrics
    if WCS_BrainMetrics and WCS_BrainMetrics.StartCombat then
        WCS_BrainMetrics:StartCombat()
    end
    
    debugPrint("Combate iniciado - Logger activado")
end

function Logger:OnCombatEnd()
    self.CurrentCombat.active = false
    
    -- Finalizar combate en WCS_BrainMetrics
    if WCS_BrainMetrics and WCS_BrainMetrics.EndCombat then
        -- Determinar resultado del combate
        local result = "won"  -- Por defecto asumimos victoria si salimos vivos
        if UnitIsDead("player") then
            result = "lost"
        end
        WCS_BrainMetrics:EndCombat(result)
    end
    
    debugPrint("Combate finalizado - Logger desactivado")
end

-- ============================================================================
-- PARSER DE COMBAT LOG
-- ============================================================================

function Logger:ParseCombatLog()
    -- En WoW 1.12, el combat log se lee desde ChatFrame2 (Combat Log)
    -- Necesitamos parsear las líneas del combat log
    
    -- Nota: Este es un método simplificado. En WoW 1.12 no hay COMBAT_LOG_EVENT_UNFILTERED
    -- Tenemos que parsear el texto del combat log o usar eventos específicos
    
    -- Por ahora, vamos a usar un enfoque basado en eventos de UI
    -- que es más confiable en WoW 1.12
end

-- ============================================================================
-- HOOKS PARA CAPTURAR EVENTOS
-- ============================================================================

function Logger:SetupHooks()
    -- Hook para CastSpell (cuando el jugador castea un hechizo)
    if not self.originalCastSpell then
        self.originalCastSpell = CastSpell
        CastSpell = function(spellId, bookType)
            -- Obtener nombre del hechizo
            local spellName = GetSpellName(spellId, bookType)
            if spellName then
                Logger:ProcessSpellCast(spellName)
            end
            -- Llamar a la función original
            return Logger.originalCastSpell(spellId, bookType)
        end
    end
    
    -- Hook para CastSpellByName
    if not self.originalCastSpellByName then
        self.originalCastSpellByName = CastSpellByName
        CastSpellByName = function(spellName, onSelf)
            -- Extraer solo el nombre del hechizo (sin rank)
            local cleanName = string.gsub(spellName, "%(.*%)", "")
            cleanName = string.gsub(cleanName, "%s+$", "")  -- Trim trailing spaces
            
            Logger:ProcessSpellCast(cleanName)
            
            -- Llamar a la función original
            return Logger.originalCastSpellByName(spellName, onSelf)
        end
    end
    
    debugPrint("Hooks instalados correctamente")
end

-- ============================================================================
-- FRAME DE EVENTOS
-- ============================================================================

function Logger:CreateEventFrame()
    if self.eventFrame then return end
    
    self.eventFrame = CreateFrame("Frame", "WCSBrainCombatLoggerFrame")
    
    -- Registrar eventos
    self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Entrar en combate
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Salir de combate
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")  -- Daño de hechizos propios
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")  -- Daño de DoTs propios
    self.eventFrame:RegisterEvent("UNIT_MANA")  -- Cambios de mana
    
    -- Handler de eventos
    self.eventFrame:SetScript("OnEvent", function()
        Logger:OnEvent(event, arg1, arg2, arg3, arg4, arg5)
    end)
    
    debugPrint("Event frame creado y eventos registrados")
end

function Logger:OnEvent(event, arg1, arg2, arg3, arg4, arg5)
    if event == "PLAYER_REGEN_DISABLED" then
        self:OnCombatStart()
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:OnCombatEnd()
        
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        -- Parsear mensaje de daño
        -- Formato típico: "Your Shadow Bolt hits Target for 500."
        -- o "Your Shadow Bolt crits Target for 1000."
        self:ParseDamageMessage(arg1)
        
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
        -- Parsear mensaje de daño periódico (DoTs)
        -- Formato típico: "Target suffers 100 Shadow damage from your Corruption."
        self:ParsePeriodicDamageMessage(arg1)
        
    elseif event == "UNIT_MANA" and arg1 == "player" then
        -- Detectar cambios de mana para estimar uso
        self:TrackManaChange()
    end
end

-- Parsear mensaje de daño directo
function Logger:ParseDamageMessage(message)
    if not message then return end
    
    -- DEBUG: Mostrar mensaje raw
    if self.Config.debugMode then
        debugPrint("[RAW DAMAGE] " .. message)
    end
    
    -- Patrón: "Your (SpellName) hits/crits (Target) for (Damage)."
    -- Buscar "Your " al inicio
    local _, endPos = string.find(message, "Your ")
    if not endPos then 
        if self.Config.debugMode then
            debugPrint("No encontró 'Your ' en el mensaje")
        end
        return 
    end
    
    -- Buscar " hits " o " crits "
    local hitsPos = string.find(message, " hits ", endPos)
    local critsPos = string.find(message, " crits ", endPos)
    local actionPos = hitsPos or critsPos
    
    if not actionPos then 
        if self.Config.debugMode then
            debugPrint("No encontró 'hits' o 'crits' en el mensaje")
        end
        return 
    end
    
    -- Extraer nombre del hechizo
    local spellName = string.sub(message, endPos + 1, actionPos - 1)
    
    -- Buscar " for "
    local forPos = string.find(message, " for ", actionPos)
    if not forPos then 
        if self.Config.debugMode then
            debugPrint("No encontró 'for' en el mensaje")
        end
        return 
    end
    
    -- Extraer daño (números después de "for ")
    local damageStr = string.sub(message, forPos + 5)
    -- Extraer solo los dígitos
    local spacePos = string.find(damageStr, " ") or string.find(damageStr, "%.")
    if spacePos then
        damageStr = string.sub(damageStr, 1, spacePos - 1)
    end
    local damage = tonumber(damageStr) or 0
    
    if spellName and damage and damage > 0 then
        if self.Config.debugMode then
            debugPrint("[PARSED] Spell: " .. spellName .. ", Damage: " .. damage)
        end
        self:ProcessSpellDamage(spellName, damage)
    else
        if self.Config.debugMode then
            debugPrint("Falló parseo final: spell=" .. tostring(spellName) .. ", dmg=" .. tostring(damage))
        end
    end
end

-- Parsear mensaje de daño periódico
function Logger:ParsePeriodicDamageMessage(message)
    if not message then return end
    
    -- DEBUG: Mostrar mensaje raw
    if self.Config.debugMode then
        debugPrint("[RAW PERIODIC] " .. message)
    end
    
    -- Patrón: "(Target) suffers (Damage) (DamageType) damage from your (SpellName)."
    -- Buscar "suffers "
    local suffersPos = string.find(message, "suffers ")
    if not suffersPos then 
        if self.Config.debugMode then
            debugPrint("No encontró 'suffers' en el mensaje")
        end
        return 
    end
    
    -- Extraer daño después de "suffers "
    local afterSuffers = string.sub(message, suffersPos + 8)
    local damageEnd = string.find(afterSuffers, " ")
    if not damageEnd then 
        if self.Config.debugMode then
            debugPrint("No encontró espacio después del daño")
        end
        return 
    end
    
    local damage = tonumber(string.sub(afterSuffers, 1, damageEnd - 1))
    
    -- Buscar "from your "
    local fromYourPos = string.find(message, "from your ")
    if not fromYourPos then 
        if self.Config.debugMode then
            debugPrint("No encontró 'from your' en el mensaje")
        end
        return 
    end
    
    -- Extraer nombre del hechizo (hasta el punto final)
    local spellName = string.sub(message, fromYourPos + 10)
    local dotPos = string.find(spellName, ".", 1, true)  -- true = plain text search
    if dotPos then
        spellName = string.sub(spellName, 1, dotPos - 1)
    end
    
    if spellName and damage and damage > 0 then
        if self.Config.debugMode then
            debugPrint("[PARSED PERIODIC] Spell: " .. spellName .. ", Damage: " .. damage)
        end
        self:ProcessSpellDamage(spellName, damage)
    else
        if self.Config.debugMode then
            debugPrint("Falló parseo periodic: spell=" .. tostring(spellName) .. ", dmg=" .. tostring(damage))
        end
    end
end

-- Tracking de cambios de mana
Logger.lastMana = 0

function Logger:TrackManaChange()
    if not self.CurrentCombat.active then return end
    
    local currentMana = UnitMana("player")
    
    if self.lastMana > currentMana then
        local manaUsed = self.lastMana - currentMana
        
        -- Solo registrar si es un cambio significativo (más de 10 mana)
        -- para evitar regeneración natural
        if manaUsed > 10 then
            self:ProcessManaUsage(manaUsed, self.CurrentCombat.lastSpellCast)
        end
    end
    
    self.lastMana = currentMana
end

-- ============================================================================
-- COMANDOS
-- ============================================================================

function Logger:RegisterCommands()
    SLASH_WCSCOMBATLOGGER1 = "/combatlogger"
    SlashCmdList["WCSCOMBATLOGGER"] = function(msg)
        local args = {}
        for word in string.gfind(msg, "%S+") do
            table.insert(args, string.lower(word))
        end
        
        if not args[1] or args[1] == "help" then
            self:ShowHelp()
        elseif args[1] == "debug" then
            self.Config.debugMode = not self.Config.debugMode
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[CombatLogger]|r Debug mode: " .. (self.Config.debugMode and "ON" or "OFF"))
        elseif args[1] == "status" then
            self:ShowStatus()
        elseif args[1] == "toggle" then
            self.enabled = not self.enabled
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[CombatLogger]|r Logger: " .. (self.enabled and "ENABLED" or "DISABLED"))
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[CombatLogger]|r Comando desconocido. Usa /combatlogger help")
        end
    end
end

function Logger:ShowHelp()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF=== COMBAT LOGGER COMMANDS ===|r")
    DEFAULT_CHAT_FRAME:AddMessage("/combatlogger status - Ver estado del logger")
    DEFAULT_CHAT_FRAME:AddMessage("/combatlogger debug - Toggle debug mode")
    DEFAULT_CHAT_FRAME:AddMessage("/combatlogger toggle - Activar/desactivar logger")
end

function Logger:ShowStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF=== COMBAT LOGGER STATUS ===|r")
    DEFAULT_CHAT_FRAME:AddMessage("Version: " .. self.VERSION)
    DEFAULT_CHAT_FRAME:AddMessage("Enabled: " .. (self.enabled and "YES" or "NO"))
    DEFAULT_CHAT_FRAME:AddMessage("Debug Mode: " .. (self.Config.debugMode and "ON" or "OFF"))
    DEFAULT_CHAT_FRAME:AddMessage("In Combat: " .. (self.CurrentCombat.active and "YES" or "NO"))
    DEFAULT_CHAT_FRAME:AddMessage("WCS_BrainMetrics: " .. (WCS_BrainMetrics and "LOADED" or "NOT FOUND"))
end

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================

function Logger:Initialize()
    self:CreateEventFrame()
    self:SetupHooks()
    self:RegisterCommands()
    
    -- Inicializar mana tracking
    if UnitMana then
        self.lastMana = UnitMana("player") or 0
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS_BrainCombatLogger]|r Sistema de captura de combate cargado v" .. self.VERSION)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS_BrainCombatLogger]|r Usa /combatlogger help para ver comandos")
end

-- Auto-inicializar cuando el addon se carga
if not Logger.initialized then
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("ADDON_LOADED")
    initFrame:SetScript("OnEvent", function()
        if event == "ADDON_LOADED" and arg1 == "WCS_Brain" then
            Logger:Initialize()
            Logger.initialized = true
        end
    end)
end

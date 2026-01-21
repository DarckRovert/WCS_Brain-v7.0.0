--[[
    WCS_BrainLearning.lua - Sistema de Aprendizaje Adaptativo v1.0.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Conecta WCS_BrainMetrics + WCS_BrainContextual para crear IA adaptativa:
    - Analiza métricas de combate para ajustar prioridades
    - Detecta acciones manuales del jugador
    - Aprende qué funciona mejor contra cada enemigo
    - Ajusta automáticamente configuración según resultados
]]--

WCS_BrainLearning = WCS_BrainLearning or {}
WCS_BrainLearning.VERSION = "1.0.0"
WCS_BrainLearning.enabled = true

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================
WCS_BrainLearning.Config = {
    learningRate = 0.1,         -- Qué tan rápido aprende (0.0-1.0)
    minSampleSize = 10,         -- Mínimo de combates para aprender
    adaptationThreshold = 0.15, -- Diferencia mínima para adaptar (15%)
    trackManualCasts = true,    -- Detectar casts manuales
    autoAdjust = true,          -- Ajustar automáticamente
    updateInterval = 30,        -- Analizar cada 30 segundos
    maxPatterns = 100,          -- Máximo de patrones a guardar
    confidenceThreshold = 0.6   -- Confianza mínima para aplicar cambios
}

-- ============================================================================
-- DATOS DE APRENDIZAJE
-- ============================================================================
WCS_BrainLearning.LearnedPatterns = {
    -- Patrones por tipo de enemigo
    -- Estructura: [enemyType] = { [spell] = {winRate, avgDamage, confidence, uses} }
    enemyPatterns = {},
    
    -- Patrones de comportamiento del jugador
    -- Estructura: [contextKey] = {spell, hpRange, manaRange, count, lastSeen}
    playerPatterns = {},
    
    -- Ajustes de prioridades aprendidos
    -- Estructura: [enemyType] = { [spell] = multiplier }
    priorityAdjustments = {},
    
    -- Rotaciones óptimas descubiertas
    -- Estructura: [enemyType] = {rotation = {spell1, spell2, ...}, winRate, uses}
    optimalRotations = {},
    
    -- Contextos donde el jugador hace overrides
    -- Estructura: [spell] = { {hp, mana, enemyType, timestamp}, ... }
    manualOverrides = {}
}

-- ============================================================================
-- ESTADO ACTUAL
-- ============================================================================
WCS_BrainLearning.State = {
    lastManualCast = nil,
    lastManualCastTime = 0,
    lastAISuggestion = nil,
    lastAISuggestionTime = 0,
    lastAnalysis = 0,
    learningActive = true,
    totalPatternsLearned = 0
}

-- ============================================================================
-- UTILIDADES
-- ============================================================================
local function getTime()
    return GetTime and GetTime() or 0
end

local function debugPrint(msg)
    if WCS_Brain and WCS_Brain.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[Learning]|r " .. tostring(msg))
    end
end

function WCS_BrainLearning:Log(message, color)
    color = color or "|cFF00FF00"
    DEFAULT_CHAT_FRAME:AddMessage(color .. "[WCS Learning]|r " .. message)
end

-- ============================================================================
-- DETECCIÓN DE CASTS MANUALES
-- ============================================================================

-- Registrar sugerencia de la IA
function WCS_BrainLearning:RegisterAISuggestion(spell)
    if not spell then return end
    self.State.lastAISuggestion = spell
    self.State.lastAISuggestionTime = getTime()
    debugPrint("IA sugirió: " .. spell)
end

-- Detectar cast manual (no sugerido por IA)
function WCS_BrainLearning:DetectManualCast(spell)
    if not self.Config.trackManualCasts or not spell then return end
    
    local currentTime = getTime()
    
    -- Si el cast fue dentro de 2 segundos de la sugerencia de IA, no es manual
    if self.State.lastAISuggestion == spell and 
       (currentTime - self.State.lastAISuggestionTime) < 2.0 then
        debugPrint("Cast de IA: " .. spell)
        return false
    end
    
    -- Es un cast manual!
    debugPrint("Cast MANUAL detectado: " .. spell)
    
    -- Capturar contexto
    local context = self:CaptureContext()
    if not context then return true end
    
    -- Guardar override manual
    if not self.LearnedPatterns.manualOverrides[spell] then
        self.LearnedPatterns.manualOverrides[spell] = {}
    end
    
    table.insert(self.LearnedPatterns.manualOverrides[spell], {
        hp = context.playerHP,
        mana = context.playerMana,
        enemyType = context.enemyType,
        enemyHP = context.enemyHP,
        timestamp = currentTime,
        inCombat = context.inCombat
    })
    
    -- Limitar tamaño
    local overrides = self.LearnedPatterns.manualOverrides[spell]
    if table.getn(overrides) > 50 then
        table.remove(overrides, 1) -- Remover el más antiguo
    end
    
    self:Log("Override manual: " .. spell .. " (HP:" .. context.playerHP .. "%, Mana:" .. context.playerMana .. "%)", "|cFFFFAA00")
    
    return true
end

-- Capturar contexto actual
function WCS_BrainLearning:CaptureContext()
    if not UnitExists("player") then return nil end
    
    local context = {
        playerHP = UnitHealth("player") / UnitHealthMax("player") * 100,
        playerMana = UnitMana("player") / UnitManaMax("player") * 100,
        inCombat = UnitAffectingCombat("player"),
        enemyType = "Unknown",
        enemyHP = 0,
        enemyLevel = 0,
        petActive = UnitExists("pet")
    }
    
    if UnitExists("target") then
        context.enemyType = UnitCreatureType("target") or "Unknown"
        context.enemyHP = UnitHealth("target") / UnitHealthMax("target") * 100
        context.enemyLevel = UnitLevel("target") or 0
    end
    
    return context
end

-- ============================================================================
-- ANÁLISIS DE MÉTRICAS
-- ============================================================================

-- Analizar efectividad de hechizos por tipo de enemigo
function WCS_BrainLearning:AnalyzeSpellEffectiveness()
    if not WCS_BrainMetrics or not WCS_BrainMetrics.Data then
        debugPrint("WCS_BrainMetrics no disponible")
        return
    end
    
    local metrics = WCS_BrainMetrics.Data
    local combatHistory = metrics.combatHistory or {}
    
    if table.getn(combatHistory) < self.Config.minSampleSize then
        debugPrint("Insuficientes combates para análisis (" .. table.getn(combatHistory) .. "/" .. self.Config.minSampleSize .. ")")
        return
    end
    
    -- Resetear patrones
    self.LearnedPatterns.enemyPatterns = {}
    
    -- Analizar por tipo de enemigo
    local enemyStats = {}
    
    for i = 1, table.getn(combatHistory) do
        local combat = combatHistory[i]
        local enemyType = combat.enemyType or "Unknown"
        
        if not enemyStats[enemyType] then
            enemyStats[enemyType] = {}
        end
        
        -- Analizar hechizos usados en este combate
        for spell, data in pairs(combat.spellsCast or {}) do
            if not enemyStats[enemyType][spell] then
                enemyStats[enemyType][spell] = {
                    wins = 0,
                    losses = 0,
                    totalDamage = 0,
                    totalCasts = 0
                }
            end
            
            local stats = enemyStats[enemyType][spell]
            stats.totalCasts = stats.totalCasts + (data.casts or 1)
            stats.totalDamage = stats.totalDamage + (data.damage or 0)
            
            if combat.result == "won" then
                stats.wins = stats.wins + 1
            elseif combat.result == "lost" then
                stats.losses = stats.losses + 1
            end
        end
    end
    
    -- Calcular win rates y guardar patrones
    local patternsLearned = 0
    
    for enemyType, spells in pairs(enemyStats) do
        self.LearnedPatterns.enemyPatterns[enemyType] = {}
        
        for spell, stats in pairs(spells) do
            local totalCombats = stats.wins + stats.losses
            
            if totalCombats >= 3 then -- Mínimo 3 combates
                local winRate = stats.wins / totalCombats
                local avgDamage = stats.totalDamage / stats.totalCasts
                local confidence = math.min(totalCombats / 20, 1.0) -- Máxima confianza a 20 combates
                
                self.LearnedPatterns.enemyPatterns[enemyType][spell] = {
                    winRate = winRate,
                    avgDamage = avgDamage,
                    confidence = confidence,
                    uses = totalCombats
                }
                
                patternsLearned = patternsLearned + 1
            end
        end
    end
    
    self.State.totalPatternsLearned = patternsLearned
    debugPrint("Análisis completado: " .. patternsLearned .. " patrones aprendidos")
end

-- Calcular ajustes de prioridades basados en patrones
function WCS_BrainLearning:CalculatePriorityAdjustments()
    self.LearnedPatterns.priorityAdjustments = {}
    
    for enemyType, spells in pairs(self.LearnedPatterns.enemyPatterns) do
        self.LearnedPatterns.priorityAdjustments[enemyType] = {}
        
        -- Encontrar mejor y peor win rate para normalizar
        local bestWinRate = 0
        local worstWinRate = 1
        
        for spell, data in pairs(spells) do
            if data.confidence >= self.Config.confidenceThreshold then
                if data.winRate > bestWinRate then bestWinRate = data.winRate end
                if data.winRate < worstWinRate then worstWinRate = data.winRate end
            end
        end
        
        -- Calcular multiplicadores
        for spell, data in pairs(spells) do
            if data.confidence >= self.Config.confidenceThreshold then
                local range = bestWinRate - worstWinRate
                
                if range > self.Config.adaptationThreshold then
                    -- Normalizar entre 0.7 y 1.3
                    local normalized = (data.winRate - worstWinRate) / range
                    local multiplier = 0.7 + (normalized * 0.6)
                    
                    self.LearnedPatterns.priorityAdjustments[enemyType][spell] = multiplier
                    
                    debugPrint(string.format("%s vs %s: %.2fx (WR: %.1f%%, Conf: %.0f%%)",
                        spell, enemyType, multiplier, data.winRate * 100, data.confidence * 100))
                end
            end
        end
    end
end

-- Detectar patrones del jugador
function WCS_BrainLearning:DetectPlayerPatterns()
    self.LearnedPatterns.playerPatterns = {}
    
    for spell, overrides in pairs(self.LearnedPatterns.manualOverrides) do
        if table.getn(overrides) >= 3 then -- Mínimo 3 overrides
            -- Calcular promedios
            local avgHP = 0
            local avgMana = 0
            local count = table.getn(overrides)
            
            for i = 1, count do
                avgHP = avgHP + overrides[i].hp
                avgMana = avgMana + overrides[i].mana
            end
            
            avgHP = avgHP / count
            avgMana = avgMana / count
            
            -- Crear patrón
            local patternKey = spell .. "_HP" .. math.floor(avgHP / 10) * 10
            
            self.LearnedPatterns.playerPatterns[patternKey] = {
                spell = spell,
                hpRange = {avgHP - 10, avgHP + 10},
                manaRange = {avgMana - 10, avgMana + 10},
                count = count,
                lastSeen = overrides[count].timestamp
            }
            
            debugPrint("Patrón del jugador: " .. spell .. " cuando HP ~" .. math.floor(avgHP) .. "%")
        end
    end
end

-- ============================================================================
-- APLICACIÓN DE APRENDIZAJE
-- ============================================================================

-- Obtener ajustes para un hechizo contra un tipo de enemigo
function WCS_BrainLearning:GetAdjustments(spell, enemyType)
    if not self.Config.autoAdjust then return nil end
    if not spell or not enemyType then return nil end
    
    local adjustments = self.LearnedPatterns.priorityAdjustments[enemyType]
    if not adjustments then return nil end
    
    local multiplier = adjustments[spell]
    if not multiplier then return nil end
    
    return {
        multiplier = multiplier,
        source = "learning"
    }
end

-- Verificar si el jugador suele usar un hechizo en este contexto
function WCS_BrainLearning:ShouldSuggestFromPattern(spell, context)
    if not context then return false end
    
    for key, pattern in pairs(self.LearnedPatterns.playerPatterns) do
        if pattern.spell == spell then
            local hpMatch = context.playerHP >= pattern.hpRange[1] and context.playerHP <= pattern.hpRange[2]
            local manaMatch = context.playerMana >= pattern.manaRange[1] and context.playerMana <= pattern.manaRange[2]
            
            if hpMatch and manaMatch then
                debugPrint("Patrón del jugador coincide: " .. spell)
                return true
            end
        end
    end
    
    return false
end

-- ============================================================================
-- AUTO-AJUSTE DE CONFIGURACIÓN
-- ============================================================================

function WCS_BrainLearning:AutoAdjustConfig()
    if not self.Config.autoAdjust then return end
    if not WCS_Brain or not WCS_BrainMetrics then return end
    
    local metrics = WCS_BrainMetrics.Data
    
    -- Ajustar umbral de salud crítica según muertes
    if metrics.totalDeaths and metrics.totalDeaths > 0 then
        local combatHistory = metrics.combatHistory or {}
        local deathHP = 0
        local deathCount = 0
        
        for i = 1, table.getn(combatHistory) do
            local combat = combatHistory[i]
            if combat.result == "lost" and combat.contextSnapshot then
                deathHP = deathHP + (combat.contextSnapshot.playerHP or 0)
                deathCount = deathCount + 1
            end
        end
        
        if deathCount >= 5 then
            local avgDeathHP = deathHP / deathCount
            
            if avgDeathHP > WCS_Brain.Config.healthCritical + 5 then
                local newThreshold = math.min(avgDeathHP + 5, 35)
                WCS_Brain.Config.healthCritical = newThreshold
                self:Log("Ajustado healthCritical a " .. newThreshold .. "% (morías con ~" .. math.floor(avgDeathHP) .. "%)", "|cFFFFAA00")
            end
        end
    end
    
    -- Ajustar uso de Life Tap según eficiencia de mana
    if metrics.manaEfficiency and metrics.manaEfficiency > 0 then
        if metrics.manaEfficiency > 2.5 then
            -- Alta eficiencia, puede usar más Life Tap
            WCS_Brain.Config.lifeTapMinHealth = 35
        elseif metrics.manaEfficiency < 1.5 then
            -- Baja eficiencia, ser más conservador
            WCS_Brain.Config.lifeTapMinHealth = 50
        end
    end
end

-- ============================================================================
-- ANÁLISIS PERIÓDICO
-- ============================================================================

function WCS_BrainLearning:PerformAnalysis()
    local currentTime = getTime()
    
    if currentTime - self.State.lastAnalysis < self.Config.updateInterval then
        return
    end
    
    self.State.lastAnalysis = currentTime
    
    debugPrint("Iniciando análisis de aprendizaje...")
    
    -- Analizar efectividad de hechizos
    self:AnalyzeSpellEffectiveness()
    
    -- Calcular ajustes de prioridades
    self:CalculatePriorityAdjustments()
    
    -- Detectar patrones del jugador
    self:DetectPlayerPatterns()
    
    -- Auto-ajustar configuración
    self:AutoAdjustConfig()
    
    debugPrint("Análisis completado")
end

-- ============================================================================
-- COMANDOS
-- ============================================================================

function WCS_BrainLearning:ShowStatus()
    self:Log("=== ESTADO DEL APRENDIZAJE ===")
    self:Log("Versión: " .. self.VERSION)
    self:Log("Estado: " .. (self.enabled and "|cFF00FF00Activo|r" or "|cFFFF0000Inactivo|r"))
    self:Log("Auto-ajuste: " .. (self.Config.autoAdjust and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
    self:Log("Patrones aprendidos: " .. self.State.totalPatternsLearned)
    
    local overrideCount = 0
    for spell, overrides in pairs(self.LearnedPatterns.manualOverrides) do
        overrideCount = overrideCount + WCS_TableCount(overrides)
    end
    self:Log("Overrides manuales detectados: " .. overrideCount)
    
    local playerPatternCount = 0
    for _ in pairs(self.LearnedPatterns.playerPatterns) do
        playerPatternCount = playerPatternCount + 1
    end
    self:Log("Patrones del jugador: " .. playerPatternCount)
end

function WCS_BrainLearning:ShowLearnedPatterns()
    self:Log("=== PATRONES APRENDIDOS ===")
    
    -- Mostrar patrones por enemigo
    for enemyType, spells in pairs(self.LearnedPatterns.enemyPatterns) do
        self:Log("|cFFFFFF00" .. enemyType .. ":|r")
        
        -- Ordenar por win rate
        local sorted = {}
        for spell, data in pairs(spells) do
            table.insert(sorted, {
                spell = spell,
                winRate = data.winRate,
                confidence = data.confidence,
                uses = data.uses
            })
        end
        
        table.sort(sorted, function(a, b) return a.winRate > b.winRate end)
        
        -- Mostrar top 5
        for i = 1, math.min(5, table.getn(sorted)) do
            local s = sorted[i]
            local color = s.winRate > 0.6 and "|cFF00FF00" or "|cFFFFAA00"
            self:Log(string.format("  %s%s|r: %.1f%% WR | Conf: %.0f%% | Usos: %d",
                color, s.spell, s.winRate * 100, s.confidence * 100, s.uses))
        end
    end
    
    -- Mostrar patrones del jugador
    if next(self.LearnedPatterns.playerPatterns) then
        self:Log("|cFFFFFF00Tus patrones:|r")
        for key, pattern in pairs(self.LearnedPatterns.playerPatterns) do
            self:Log(string.format("  %s cuando HP ~%d%%, Mana ~%d%% (x%d veces)",
                pattern.spell, pattern.hpRange[1], pattern.manaRange[1], pattern.count))
        end
    end
end

function WCS_BrainLearning:ResetLearning()
    self.LearnedPatterns = {
        enemyPatterns = {},
        playerPatterns = {},
        priorityAdjustments = {},
        optimalRotations = {},
        manualOverrides = {}
    }
    
    self.State.totalPatternsLearned = 0
    
    self:Log("Aprendizaje reseteado", "|cFFFF0000")
end

function WCS_BrainLearning:AnalyzeAndReport()
    self:PerformAnalysis()
    self:ShowLearnedPatterns()
end

-- ============================================================================
-- INTEGRACIÓN CON WCS_BRAIN
-- ============================================================================

-- Hook para detectar casts
function WCS_BrainLearning:HookSpellCasting()
    if not WCS_Brain then return end
    
    -- Hook en Execute para registrar sugerencias de IA
    if not self.originalExecute then
        self.originalExecute = WCS_Brain.Execute
    end
    
    WCS_Brain.Execute = function(self)
        -- Obtener decisión antes de ejecutar
        local decision = self:MakeDecision()
        if decision and decision.spell then
            WCS_BrainLearning:RegisterAISuggestion(decision.spell)
        end
        
        -- Ejecutar original
        return WCS_BrainLearning.originalExecute(self)
    end
end

-- ============================================================================
-- EVENTOS
-- ============================================================================

function WCS_BrainLearning:OnSpellCast(spell)
    self:DetectManualCast(spell)
end

function WCS_BrainLearning:OnCombatEnd()
    -- Analizar después de cada combate
    self:PerformAnalysis()
end

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================

function WCS_BrainLearning:Initialize()
    self:Log("Sistema de Aprendizaje v" .. self.VERSION .. " inicializado")
    
    -- Cargar datos guardados
    if WCS_BrainLearningSaved then
        self.LearnedPatterns = WCS_BrainLearningSaved.patterns or self.LearnedPatterns
        self.Config = WCS_BrainLearningSaved.config or self.Config
        self:Log("Datos de aprendizaje cargados")
    end
    
    -- Hook sistemas
    self:HookSpellCasting()
    
    -- Análisis inicial
    self:PerformAnalysis()
end

function WCS_BrainLearning:SaveData()
    WCS_BrainLearningSaved = {
        version = self.VERSION,
        patterns = self.LearnedPatterns,
        config = self.Config
    }
end

-- ============================================================================
-- FRAME DE ACTUALIZACIÓN
-- ============================================================================

local learningFrame = CreateFrame("Frame")
learningFrame:RegisterEvent("ADDON_LOADED")
learningFrame:RegisterEvent("PLAYER_LOGOUT")
learningFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
learningFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
learningFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

learningFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "WCS_Brain" then
        WCS_BrainLearning:Initialize()
        
    elseif event == "PLAYER_LOGOUT" then
        WCS_BrainLearning:SaveData()
        
    elseif event == "UNIT_SPELLCAST_SENT" and arg1 == "player" then
        -- arg2 = spell name
        WCS_BrainLearning:OnSpellCast(arg2)
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Salió de combate
        WCS_BrainLearning:OnCombatEnd()
    end
end)

-- Update periódico
learningFrame.updateTimer = 0
learningFrame:SetScript("OnUpdate", function()
    learningFrame.updateTimer = learningFrame.updateTimer + arg1
    
    if learningFrame.updateTimer >= 5.0 then
        learningFrame.updateTimer = 0
        
        if WCS_BrainLearning.enabled then
            WCS_BrainLearning:PerformAnalysis()
        end
    end
end)

-- ============================================================================
-- COMANDOS SLASH
-- ============================================================================

SLASH_BRAINLEARN1 = "/brainlearn"
SLASH_BRAINLEARN2 = "/learn"
SlashCmdList["BRAINLEARN"] = function(msg)
    local cmd = string.lower(msg or "")
    
    if cmd == "status" or cmd == "" then
        WCS_BrainLearning:ShowStatus()
        
    elseif cmd == "patterns" or cmd == "show" then
        WCS_BrainLearning:ShowLearnedPatterns()
        
    elseif cmd == "reset" then
        WCS_BrainLearning:ResetLearning()
        
    elseif cmd == "analyze" then
        WCS_BrainLearning:AnalyzeAndReport()
        
    elseif cmd == "toggle" then
        WCS_BrainLearning.enabled = not WCS_BrainLearning.enabled
        WCS_BrainLearning:Log("Aprendizaje: " .. (WCS_BrainLearning.enabled and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
        
    elseif cmd == "autoadjust" then
        WCS_BrainLearning.Config.autoAdjust = not WCS_BrainLearning.Config.autoAdjust
        WCS_BrainLearning:Log("Auto-ajuste: " .. (WCS_BrainLearning.Config.autoAdjust and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
        
    elseif cmd == "debug" then
        -- Mostrar información de debug
        WCS_BrainLearning:Log("=== DEBUG INFO ===")
        if WCS_BrainMetrics and WCS_BrainMetrics.Data then
            local combatCount = WCS_TableCount(WCS_BrainMetrics.Data.combatHistory or {})
            WCS_BrainLearning:Log("Combates registrados: " .. combatCount)
            WCS_BrainLearning:Log("Mínimo requerido: " .. WCS_BrainLearning.Config.minSampleSize)
            WCS_BrainLearning:Log("WCS_BrainMetrics: |cFF00FF00ACTIVO|r")
            if combatCount > 0 then
                local lastCombat = WCS_BrainMetrics.Data.combatHistory[combatCount]
                WCS_BrainLearning:Log("Último combate: " .. (lastCombat.enemyType or "Unknown"))
                
                -- Contar hechizos únicos manualmente (spellsCast usa keys de string, no índices numéricos)
                local spellCount = 0
                if lastCombat.spellsCast then
                    for _ in pairs(lastCombat.spellsCast) do
                        spellCount = spellCount + 1
                    end
                end
                WCS_BrainLearning:Log("Hechizos únicos usados: " .. spellCount)
                
                -- Mostrar detalles de cada hechizo
                if lastCombat.spellsCast then
                    for spell, data in pairs(lastCombat.spellsCast) do
                        WCS_BrainLearning:Log("  * " .. spell .. ": " .. (data.casts or 0) .. " casts, " .. (data.damage or 0) .. " dmg")
                    end
                end
            end
        else
            WCS_BrainLearning:Log("WCS_BrainMetrics: |cFFFF0000NO DISPONIBLE|r")
        end
        WCS_BrainLearning:Log("Learning enabled: " .. (WCS_BrainLearning.enabled and "SI" or "NO"))
        
    else
        WCS_BrainLearning:Log("=== COMANDOS ===")
        WCS_BrainLearning:Log("/brainlearn status - Ver estado")
        WCS_BrainLearning:Log("/brainlearn patterns - Ver patrones aprendidos")
        WCS_BrainLearning:Log("/brainlearn analyze - Analizar ahora")
        WCS_BrainLearning:Log("/brainlearn debug - Ver info detallada (con hechizos)")
        WCS_BrainLearning:Log("/brainlearn reset - Resetear aprendizaje")
        WCS_BrainLearning:Log("/brainlearn toggle - Activar/desactivar")
        WCS_BrainLearning:Log("/brainlearn autoadjust - Toggle auto-ajuste")
    end
end

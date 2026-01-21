--[[
    WCS_BrainCombatController.lua - Controlador Central de Combate
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.0.0
    
    Coordina la integración entre:
    - WCS_BrainDQN (Red Neuronal)
    - WCS_BrainSmartAI (Reglas Heurísticas Avanzadas)
    - WCS_BrainAI (Sistema Base)
    - WCS_BrainPetAI (Control de Mascota)
]]--

WCS_BrainCombatController = WCS_BrainCombatController or {}
local Controller = WCS_BrainCombatController

Controller.VERSION = "1.0.0"
Controller.enabled = true
Controller.lastDecision = nil
Controller.lastDecisionTime = 0
Controller.decisionHistory = {}

-- ============================================================================
-- CONFIGURACIÓN DE PRIORIDADES
-- ============================================================================
Controller.Config = {
    -- Modo de operación: "hybrid", "dqn_only", "smartai_only", "heuristic_only"
    mode = "hybrid",
    
    -- Pesos para el sistema híbrido (deben sumar 1.0)
    weights = {
        dqn = 0.4,        -- Red neuronal
        smartai = 0.4,    -- Análisis heurístico avanzado
        heuristic = 0.2   -- Reglas básicas
    },
    
    -- Umbrales de confianza
    confidenceThreshold = 0.6,
    
    -- Throttling (segundos entre decisiones)
    minDecisionInterval = 0.1,
    
    -- Integración con PetAI
    petAIEnabled = true,
    petAICoordination = true
}

-- ============================================================================
-- UTILIDADES LUA 5.0
-- ============================================================================
local function getTime()
    return GetTime and GetTime() or 0
end

local function debugPrint(msg)
    if WCS_Brain and WCS_Brain.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[CombatController]|r " .. tostring(msg))
    end
end

-- ============================================================================
-- SISTEMA DE CACHE COMPARTIDO
-- ============================================================================
Controller.SharedCache = {
    -- Estado de combate
    inCombat = false,
    combatStart = 0,
    combatDuration = 0,
    
    -- Target info
    targetID = nil,
    targetHealth = 0,
    targetHealthMax = 0,
    targetHealthPercent = 0,
    
    -- Player info
    playerHealth = 0,
    playerHealthMax = 0,
    playerHealthPercent = 0,
    playerMana = 0,
    playerManaMax = 0,
    playerManaPercent = 0,
    
    -- DoTs tracking (compartido entre todos los sistemas)
    activeDoTs = {},
    
    -- Threat tracking
    threatLevel = 0,
    
    -- Pet info
    petExists = false,
    petHealth = 0,
    petHealthPercent = 0,
    petMana = 0,
    petManaPercent = 0,
    
    -- Última actualización
    lastUpdate = 0
}

-- Actualizar cache compartido
function Controller:UpdateSharedCache()
    local now = getTime()
    local cache = self.SharedCache
    
    -- Combat state
    cache.inCombat = UnitAffectingCombat("player")
    if cache.inCombat and cache.combatStart == 0 then
        cache.combatStart = now
    elseif not cache.inCombat then
        cache.combatStart = 0
    end
    cache.combatDuration = cache.inCombat and (now - cache.combatStart) or 0
    
    -- Target info
    if UnitExists("target") then
        cache.targetHealth = UnitHealth("target") or 0
        cache.targetHealthMax = UnitHealthMax("target") or 1
        cache.targetHealthPercent = (cache.targetHealth / cache.targetHealthMax) * 100
        
        -- Target ID (compatible con WCS_BrainAI)
        if WCS_BrainAI and WCS_BrainAI.GetTargetID then
            cache.targetID = WCS_BrainAI:GetTargetID()
        end
    else
        cache.targetID = nil
        cache.targetHealth = 0
        cache.targetHealthMax = 0
        cache.targetHealthPercent = 0
    end
    
    -- Player info
    cache.playerHealth = UnitHealth("player") or 0
    cache.playerHealthMax = UnitHealthMax("player") or 1
    cache.playerHealthPercent = (cache.playerHealth / cache.playerHealthMax) * 100
    cache.playerMana = UnitMana("player") or 0
    cache.playerManaMax = UnitManaMax("player") or 1
    cache.playerManaPercent = (cache.playerMana / cache.playerManaMax) * 100
    
    -- Pet info
    cache.petExists = UnitExists("pet")
    if cache.petExists then
        cache.petHealth = UnitHealth("pet") or 0
        local petHealthMax = UnitHealthMax("pet") or 1
        cache.petHealthPercent = (cache.petHealth / petHealthMax) * 100
        cache.petMana = UnitMana("pet") or 0
        local petManaMax = UnitManaMax("pet") or 1
        cache.petManaPercent = (cache.petMana / petManaMax) * 100
    end
    
    -- Sincronizar DoTs con WCS_BrainAI si existe
    if WCS_BrainAI and WCS_BrainAI.DoTTimers then
        cache.activeDoTs = WCS_BrainAI.DoTTimers
    end
    
    cache.lastUpdate = now
end

-- ============================================================================
-- SISTEMA DE DECISIÓN UNIFICADO
-- ============================================================================

-- Estructura de decisión normalizada
--[[
    Decision = {
        spell = "Shadow Bolt",
        action = "CAST",
        priority = 1-10,
        confidence = 0.0-1.0,
        source = "dqn" | "smartai" | "heuristic" | "emergency",
        reason = "descripción",
        metadata = { ... }
    }
]]--

-- Obtener decisión de emergencia (máxima prioridad)
function Controller:GetEmergencyDecision()
    local cache = self.SharedCache
    
    -- Jugador a punto de morir
    if cache.playerHealthPercent < 15 then
        -- Buscar Healthstone
        if WCS_BrainCore and WCS_BrainCore.HasHealthstone and WCS_BrainCore:HasHealthstone() then
            return {
                spell = "Healthstone",
                action = "USE_ITEM",
                priority = 10,
                confidence = 1.0,
                source = "emergency",
                reason = "Salud crítica del jugador"
            }
        end
        
        -- Death Coil si está disponible
        if WCS_BrainCore and WCS_BrainCore.FindSpellSlot then
            local slot = WCS_BrainCore:FindSpellSlot("Death Coil")
            if slot then
                return {
                    spell = "Death Coil",
                    action = "CAST",
                    priority = 10,
                    confidence = 1.0,
                    source = "emergency",
                    reason = "Salud crítica - Death Coil"
                }
            end
        end
        
        -- Drain Life como último recurso
        if WCS_BrainCore and WCS_BrainCore.FindSpellSlot then
            local slot = WCS_BrainCore:FindSpellSlot("Drain Life")
            if slot then
                return {
                    spell = "Drain Life",
                    action = "CAST",
                    priority = 10,
                    confidence = 1.0,
                    source = "emergency",
                    reason = "Salud crítica - Drain Life"
                }
            end
        end
    end
    
    -- Mascota a punto de morir (si es importante)
    if cache.petExists and cache.petHealthPercent < 10 then
        local petName = UnitName("pet")
        -- No sacrificar Voidwalker o Felhunter fácilmente
        if petName and (string.find(petName, "Voidwalker") or string.find(petName, "Felhunter")) then
            if WCS_BrainCore and WCS_BrainCore.FindSpellSlot then
                local slot = WCS_BrainCore:FindSpellSlot("Health Funnel")
                if slot and cache.playerHealthPercent > 40 then
                    return {
                        spell = "Health Funnel",
                        action = "CAST",
                        priority = 9,
                        confidence = 0.9,
                        source = "emergency",
                        reason = "Mascota crítica - Health Funnel"
                    }
                end
            end
        end
    end
    
    -- Sin mana y en combate
    if cache.inCombat and cache.playerManaPercent < 5 then
        if WCS_BrainCore and WCS_BrainCore.FindSpellSlot then
            local slot = WCS_BrainCore:FindSpellSlot("Life Tap")
            if slot and cache.playerHealthPercent > 30 then
                return {
                    spell = "Life Tap",
                    action = "CAST",
                    priority = 9,
                    confidence = 0.95,
                    source = "emergency",
                    reason = "Mana crítico - Life Tap"
                }
            end
        end
    end
    
    return nil
end

-- Obtener decisión del DQN
function Controller:GetDQNDecision()
    if not WCS_BrainDQN or not WCS_BrainDQN.enabled then
        return nil
    end
    
    if not WCS_BrainIntegration or not WCS_BrainIntegration.GetDQNAction then
        return nil
    end
    
    local decision = WCS_BrainIntegration:GetDQNAction()
    if decision then
        -- Normalizar formato
        return {
            spell = decision.spell,
            action = decision.action or "CAST",
            priority = decision.priority or 5,
            confidence = 0.7, -- Confianza base del DQN
            source = "dqn",
            reason = decision.reason or "DQN Neural Network"
        }
    end
    
    return nil
end

-- Obtener decisión del SmartAI
function Controller:GetSmartAIDecision()
    if not WCS_BrainSmartAI then
        return nil
    end
    
    -- Primero obtener decisión base de BrainAI
    local baseDecision = nil
    if WCS_BrainAI and WCS_BrainAI.OriginalGetBestAction then
        baseDecision = WCS_BrainAI:OriginalGetBestAction()
    elseif WCS_BrainAI and WCS_BrainAI.GetBestAction then
        baseDecision = WCS_BrainAI:GetBestAction()
    end
    
    if not baseDecision then
        return nil
    end
    
    -- Mejorar con SmartAI
    local enhancedDecision = WCS_BrainSmartAI:EnhanceDecision(baseDecision)
    if enhancedDecision then
        return {
            spell = enhancedDecision.spell,
            action = enhancedDecision.action or "CAST",
            priority = enhancedDecision.priority or 5,
            confidence = 0.8, -- SmartAI tiene alta confianza
            source = "smartai",
            reason = enhancedDecision.reason or "SmartAI Enhanced"
        }
    end
    
    return nil
end

-- Obtener decisión heurística básica
function Controller:GetHeuristicDecision()
    if not WCS_BrainAI or not WCS_BrainAI.GetBestAction then
        return nil
    end
    
    local decision = WCS_BrainAI:GetBestAction()
    if decision then
        return {
            spell = decision.spell,
            action = decision.action or "CAST",
            priority = decision.priority or 3,
            confidence = 0.5, -- Confianza base
            source = "heuristic",
            reason = decision.reason or "Basic Heuristic"
        }
    end
    
    return nil
end

-- ============================================================================
-- SISTEMA DE ARBITRAJE
-- ============================================================================

-- Combinar múltiples decisiones en modo híbrido
function Controller:ArbitrateDecisions(decisions)
    if not decisions or table.getn(decisions) == 0 then
        return nil
    end
    
    -- Si solo hay una decisión, retornarla
    if table.getn(decisions) == 1 then
        return decisions[1]
    end
    
    -- Calcular scores ponderados
    local bestDecision = nil
    local bestScore = -1
    
    for i = 1, table.getn(decisions) do
        local decision = decisions[i]
        local weight = 0
        
        -- Obtener peso según la fuente
        if decision.source == "emergency" then
            weight = 1.0 -- Emergencias siempre tienen máxima prioridad
        elseif decision.source == "dqn" then
            weight = self.Config.weights.dqn
        elseif decision.source == "smartai" then
            weight = self.Config.weights.smartai
        elseif decision.source == "heuristic" then
            weight = self.Config.weights.heuristic
        end
        
        -- Score = (prioridad * confianza * peso)
        local score = (decision.priority or 5) * (decision.confidence or 0.5) * weight
        
        if score > bestScore then
            bestScore = score
            bestDecision = decision
        end
    end
    
    return bestDecision
end

-- Obtener la mejor decisión de combate
function Controller:GetBestCombatDecision()
    local now = getTime()
    
    -- Throttling: no tomar decisiones muy rápido
    if now - self.lastDecisionTime < self.Config.minDecisionInterval then
        return self.lastDecision
    end
    
    -- Actualizar cache compartido
    self:UpdateSharedCache()
    
    -- Recolectar decisiones de todos los sistemas
    local decisions = {}
    
    -- 1. Emergencias (máxima prioridad)
    local emergency = self:GetEmergencyDecision()
    if emergency then
        table.insert(decisions, emergency)
        -- Si hay emergencia, ejecutar inmediatamente
        self.lastDecision = emergency
        self.lastDecisionTime = now
        debugPrint("EMERGENCIA: " .. emergency.spell .. " - " .. emergency.reason)
        return emergency
    end
    
    -- 2. Según el modo de operación
    if self.Config.mode == "hybrid" then
        -- Recolectar de todos los sistemas
        local dqn = self:GetDQNDecision()
        if dqn then table.insert(decisions, dqn) end
        
        local smartai = self:GetSmartAIDecision()
        if smartai then table.insert(decisions, smartai) end
        
        local heuristic = self:GetHeuristicDecision()
        if heuristic then table.insert(decisions, heuristic) end
        
    elseif self.Config.mode == "dqn_only" then
        local dqn = self:GetDQNDecision()
        if dqn then table.insert(decisions, dqn) end
        
    elseif self.Config.mode == "smartai_only" then
        local smartai = self:GetSmartAIDecision()
        if smartai then table.insert(decisions, smartai) end
        
    elseif self.Config.mode == "heuristic_only" then
        local heuristic = self:GetHeuristicDecision()
        if heuristic then table.insert(decisions, heuristic) end
    end
    
    -- Arbitrar entre las decisiones
    local finalDecision = self:ArbitrateDecisions(decisions)
    
    if finalDecision then
        self.lastDecision = finalDecision
        self.lastDecisionTime = now
        
        -- Guardar en historial
        table.insert(self.decisionHistory, {
            time = now,
            decision = finalDecision
        })
        
        -- Limitar historial a 50 entradas
        if table.getn(self.decisionHistory) > 50 then
            table.remove(self.decisionHistory, 1)
        end
        
        debugPrint("Decisión: " .. finalDecision.spell .. " [" .. finalDecision.source .. "] - " .. finalDecision.reason)
        
        -- Coordinar con PetAI
        self:CoordinateWithPet()
    end
    
    return finalDecision
end

-- ============================================================================
-- COORDINACIÓN CON PETAI
-- ============================================================================

function Controller:CoordinateWithPet()
    if not self.Config.petAIEnabled or not self.Config.petAICoordination then
        return
    end
    
    if not WCS_BrainPetAI or not WCS_BrainPetAI.ENABLED then
        return
    end
    
    -- Informar al PetAI sobre la última decisión del jugador
    if self.lastDecision and WCS_BrainPetAI.OnPlayerAction then
        WCS_BrainPetAI:OnPlayerAction(self.lastDecision)
    end
end

-- ============================================================================
-- COMANDOS Y CONFIGURACIÓN
-- ============================================================================

function Controller:SetMode(mode)
    local validModes = {
        hybrid = true,
        dqn_only = true,
        smartai_only = true,
        heuristic_only = true
    }
    
    if validModes[mode] then
        self.Config.mode = mode
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[CombatController]|r Modo cambiado a: " .. mode)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[CombatController]|r Modo inválido. Opciones: hybrid, dqn_only, smartai_only, heuristic_only")
    end
end

function Controller:SetWeights(dqn, smartai, heuristic)
    local total = dqn + smartai + heuristic
    if math.abs(total - 1.0) > 0.01 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[CombatController]|r Los pesos deben sumar 1.0")
        return
    end
    
    self.Config.weights.dqn = dqn
    self.Config.weights.smartai = smartai
    self.Config.weights.heuristic = heuristic
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[CombatController]|r Pesos actualizados: DQN=" .. dqn .. ", SmartAI=" .. smartai .. ", Heuristic=" .. heuristic)
end

function Controller:ShowStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[CombatController]|r === Estado ===")
    DEFAULT_CHAT_FRAME:AddMessage("Versión: " .. self.VERSION)
    DEFAULT_CHAT_FRAME:AddMessage("Modo: " .. self.Config.mode)
    DEFAULT_CHAT_FRAME:AddMessage("Pesos: DQN=" .. self.Config.weights.dqn .. ", SmartAI=" .. self.Config.weights.smartai .. ", Heuristic=" .. self.Config.weights.heuristic)
    DEFAULT_CHAT_FRAME:AddMessage("PetAI Coordinación: " .. (self.Config.petAICoordination and "Activada" or "Desactivada"))
    
    if self.lastDecision then
        DEFAULT_CHAT_FRAME:AddMessage("Última decisión: " .. self.lastDecision.spell .. " [" .. self.lastDecision.source .. "]")
    end
end

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================

function Controller:Initialize()
    debugPrint("Inicializando Combat Controller v" .. self.VERSION)
    
    -- Verificar dependencias
    if not WCS_BrainCore then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[CombatController]|r ERROR: WCS_BrainCore no encontrado")
        self.enabled = false
        return
    end
    
    -- Inicializar cache
    self:UpdateSharedCache()
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[CombatController]|r Inicializado v" .. self.VERSION .. " - Modo: " .. self.Config.mode)
end

-- Slash commands
SLASH_WCSCOMBAT1 = "/wcscombat"
SlashCmdList["WCSCOMBAT"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, word)
    end
    
    if args[1] == "mode" and args[2] then
        Controller:SetMode(args[2])
    elseif args[1] == "weights" and args[2] and args[3] and args[4] then
        Controller:SetWeights(tonumber(args[2]), tonumber(args[3]), tonumber(args[4]))
    elseif args[1] == "status" then
        Controller:ShowStatus()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[CombatController]|r Comandos:")
        DEFAULT_CHAT_FRAME:AddMessage("/wcscombat mode <hybrid|dqn_only|smartai_only|heuristic_only>")
        DEFAULT_CHAT_FRAME:AddMessage("/wcscombat weights <dqn> <smartai> <heuristic> (deben sumar 1.0)")
        DEFAULT_CHAT_FRAME:AddMessage("/wcscombat status")
    end
end

-- Auto-inicializar
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "WCS_Brain" then
        -- Delay para asegurar que otros módulos estén cargados
        local delayFrame = CreateFrame("Frame")
        local elapsed = 0
        delayFrame:SetScript("OnUpdate", function()
            elapsed = elapsed + arg1
            if elapsed > 2.0 then
                Controller:Initialize()
                delayFrame:SetScript("OnUpdate", nil)
            end
        end)
    end
end)

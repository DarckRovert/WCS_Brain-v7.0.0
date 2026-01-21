--[[
    WCS_BrainCombatCache.lua - Cache Compartido de Estado de Combate
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.0.0
    
    Proporciona un cache centralizado para evitar duplicación de cálculos
    entre DQN, SmartAI y PetAI
]]--

WCS_BrainCombatCache = WCS_BrainCombatCache or {}
local Cache = WCS_BrainCombatCache

Cache.VERSION = "1.0.0"

-- ============================================================================
-- UTILIDADES LUA 5.0
-- ============================================================================
local function getTime()
    return GetTime and GetTime() or 0
end

-- Función para contar elementos en array (compatible Lua 5.0)
local function tableCount(t)
    return table.getn(t)
end

-- ============================================================================
-- CACHE DE DOTS COMPARTIDO
-- ============================================================================
Cache.DoTs = {
    -- Estructura: [targetID] = { [dotName] = {applied = time, duration = dur, damage = dmg} }
    active = {},
    
    -- Duraciones base (sin talentos)
    baseDurations = {
        ["Corruption"] = 18,
        ["Immolate"] = 15,
        ["Curse of Agony"] = 24,
        ["Siphon Life"] = 30,
        ["Curse of Doom"] = 60,
        ["Curse of Tongues"] = 30,
        ["Curse of Weakness"] = 120,
        ["Curse of the Elements"] = 300,
        ["Curse of Shadow"] = 300
    }
}

-- Registrar aplicación de DoT
function Cache.DoTs:Register(dotName, targetID, damage)
    if not targetID or not dotName then return end
    
    if not self.active[targetID] then
        self.active[targetID] = {}
    end
    
    local duration = self.baseDurations[dotName] or 18
    self.active[targetID][dotName] = {
        applied = getTime(),
        duration = duration,
        damage = damage or 0
    }
end

-- Obtener tiempo restante de DoT
function Cache.DoTs:GetTimeRemaining(dotName, targetID)
    if not targetID or not self.active[targetID] then return 0 end
    
    local dot = self.active[targetID][dotName]
    if not dot then return 0 end
    
    local elapsed = getTime() - dot.applied
    local remaining = dot.duration - elapsed
    
    if remaining < 0 then
        self.active[targetID][dotName] = nil
        return 0
    end
    
    return remaining
end

-- Verificar si DoT necesita refresh (pandemic window)
function Cache.DoTs:NeedsRefresh(dotName, targetID, pandemicPercent)
    pandemicPercent = pandemicPercent or 0.3
    local remaining = self:GetTimeRemaining(dotName, targetID)
    local baseDuration = self.baseDurations[dotName] or 18
    return remaining < (baseDuration * pandemicPercent)
end

-- Limpiar DoTs expirados
function Cache.DoTs:Cleanup()
    local now = getTime()
    local toRemove = {}
    
    for targetID, dots in pairs(self.active) do
        for dotName, data in pairs(dots) do
            local remaining = data.duration - (now - data.applied)
            if remaining <= 0 then
                if not toRemove[targetID] then
                    toRemove[targetID] = {}
                end
                table.insert(toRemove[targetID], dotName)
            end
        end
    end
    
    for targetID, dotList in pairs(toRemove) do
        for i, dotName in ipairs(dotList) do
            self.active[targetID][dotName] = nil
        end
        
        -- Si el target no tiene más DoTs, remover entrada
        local hasDoTs = false
        for k, v in pairs(self.active[targetID]) do
            hasDoTs = true
            break
        end
        if not hasDoTs then
            self.active[targetID] = nil
        end
    end
end

-- Obtener todos los DoTs activos en un target
function Cache.DoTs:GetActiveDoTs(targetID)
    if not targetID or not self.active[targetID] then return {} end
    
    local result = {}
    for dotName, data in pairs(self.active[targetID]) do
        local remaining = self:GetTimeRemaining(dotName, targetID)
        if remaining > 0 then
            table.insert(result, {
                name = dotName,
                remaining = remaining,
                damage = data.damage
            })
        end
    end
    return result
end

-- ============================================================================
-- CACHE DE AMENAZA (THREAT)
-- ============================================================================
Cache.Threat = {
    playerThreat = 0,
    lastReset = 0,
    history = {}
}

-- Agregar amenaza
function Cache.Threat:Add(amount, source)
    self.playerThreat = self.playerThreat + amount
    
    table.insert(self.history, {
        time = getTime(),
        amount = amount,
        source = source or "unknown",
        total = self.playerThreat
    })
    
    -- Limitar historial
    local historyCount = tableCount(self.history)
    if historyCount > 100 then
        table.remove(self.history, 1)
    end
end

-- Resetear amenaza (cambio de target, salir de combate)
function Cache.Threat:Reset()
    self.playerThreat = 0
    self.lastReset = getTime()
    self.history = {}
end

-- Obtener nivel de amenaza estimado (0-100)
function Cache.Threat:GetLevel()
    -- Esto es una estimación, en Vanilla no hay API de threat real
    -- Basado en acumulación de amenaza vs tiempo en combate
    local combatDuration = 0
    if WCS_BrainCombatController and WCS_BrainCombatController.SharedCache then
        combatDuration = WCS_BrainCombatController.SharedCache.combatDuration
    end
    
    if combatDuration <= 0 then return 0 end
    
    -- Threat por segundo
    local tps = self.playerThreat / combatDuration
    
    -- Normalizar a 0-100 (asumiendo 100 TPS = 100%)
    local level = math.min((tps / 100) * 100, 100)
    return level
end

-- ============================================================================
-- CACHE DE COOLDOWNS
-- ============================================================================
Cache.Cooldowns = {
    spells = {},
    items = {}
}

-- Registrar cooldown de hechizo
function Cache.Cooldowns:RegisterSpell(spellName, duration)
    self.spells[spellName] = {
        start = getTime(),
        duration = duration
    }
end

-- Verificar si hechizo está en cooldown
function Cache.Cooldowns:IsSpellOnCooldown(spellName)
    local cd = self.spells[spellName]
    if not cd then return false end
    
    local elapsed = getTime() - cd.start
    if elapsed >= cd.duration then
        self.spells[spellName] = nil
        return false
    end
    
    return true
end

-- Obtener tiempo restante de cooldown
function Cache.Cooldowns:GetSpellCooldownRemaining(spellName)
    local cd = self.spells[spellName]
    if not cd then return 0 end
    
    local elapsed = getTime() - cd.start
    local remaining = cd.duration - elapsed
    
    if remaining <= 0 then
        self.spells[spellName] = nil
        return 0
    end
    
    return remaining
end

-- ============================================================================
-- CACHE DE ANÁLISIS DE TARGET
-- ============================================================================
Cache.Target = {
    current = nil,
    healthHistory = {},
    dpsEstimate = 0,
    ttk = 0, -- Time to kill
    lastUpdate = 0
}

-- Actualizar análisis de target
function Cache.Target:Update(targetID, health, healthMax)
    local now = getTime()
    
    if targetID ~= self.current then
        -- Nuevo target, resetear
        self.current = targetID
        self.healthHistory = {}
        self.dpsEstimate = 0
        self.ttk = 0
    end
    
    -- Guardar health en historial
    table.insert(self.healthHistory, {
        time = now,
        health = health,
        healthMax = healthMax
    })
    
    -- Limitar historial a 20 entradas
    local historyCount = tableCount(self.healthHistory)
    if historyCount > 20 then
        table.remove(self.healthHistory, 1)
    end
    
    -- Calcular DPS si tenemos suficiente historial
    historyCount = tableCount(self.healthHistory)
    if historyCount >= 3 then
        local oldest = self.healthHistory[1]
        local newest = self.healthHistory[historyCount]
        
        local timeDiff = newest.time - oldest.time
        local healthDiff = oldest.health - newest.health
        
        if timeDiff > 0 and healthDiff > 0 then
            self.dpsEstimate = healthDiff / timeDiff
            
            -- Calcular TTK
            if self.dpsEstimate > 0 then
                self.ttk = newest.health / self.dpsEstimate
            end
        end
    end
    
    self.lastUpdate = now
end

-- Obtener DPS estimado
function Cache.Target:GetDPS()
    return self.dpsEstimate
end

-- Obtener tiempo estimado hasta muerte
function Cache.Target:GetTTK()
    return self.ttk
end

-- ============================================================================
-- SINCRONIZACIÓN CON SISTEMAS EXISTENTES
-- ============================================================================

-- Sincronizar con WCS_BrainAI.DoTTimers
function Cache:SyncWithBrainAI()
    if not WCS_BrainAI or not WCS_BrainAI.DoTTimers then return end
    
    -- Copiar DoTs de BrainAI a cache compartido
    for targetID, dots in pairs(WCS_BrainAI.DoTTimers) do
        for dotName, data in pairs(dots) do
            if not self.DoTs.active[targetID] then
                self.DoTs.active[targetID] = {}
            end
            self.DoTs.active[targetID][dotName] = data
        end
    end
    
    -- Actualizar BrainAI con cache compartido
    WCS_BrainAI.DoTTimers = self.DoTs.active
end

-- Sincronizar con WCS_BrainSmartAI.CombatCache
function Cache:SyncWithSmartAI()
    if not WCS_BrainSmartAI then return end
    
    -- Compartir threat data
    if WCS_BrainSmartAI.CombatCache then
        WCS_BrainSmartAI.CombatCache.playerThreat = self.Threat.playerThreat
    end
end

-- ============================================================================
-- LIMPIEZA PERIÓDICA
-- ============================================================================

Cache.lastCleanup = 0
Cache.cleanupInterval = 5 -- segundos

function Cache:PeriodicCleanup()
    local now = getTime()
    if now - self.lastCleanup < self.cleanupInterval then
        return
    end
    
    self.DoTs:Cleanup()
    self.lastCleanup = now
end

-- ============================================================================
-- EVENTOS
-- ============================================================================

local cacheFrame = CreateFrame("Frame")
cacheFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
cacheFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

cacheFrame:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_ENABLED" then
        -- Salir de combate, resetear threat
        Cache.Threat:Reset()
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Cambio de target, resetear threat
        Cache.Threat:Reset()
    end
end)

-- Update loop
local updateFrame = CreateFrame("Frame")
local elapsed = 0
updateFrame:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed > 1.0 then
        Cache:PeriodicCleanup()
        Cache:SyncWithBrainAI()
        Cache:SyncWithSmartAI()
        elapsed = 0
    end
end)

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFAA[CombatCache]|r Inicializado v" .. Cache.VERSION)

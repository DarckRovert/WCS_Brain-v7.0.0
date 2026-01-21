--[[
    WCS_BrainCombatCache_GuardianExt.lua
    Extensiones del CombatCache para Modo Guardián
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.1.0
    
    Este archivo extiende el CombatCache con funcionalidades específicas
    para mejorar la detección de amenaza en el modo Guardián.
    
    CHANGELOG v1.1.0:
    - Agregado sistema de detección de atacantes via CombatLog
    - Tracking de atacantes en tiempo real
    - Priorización de atacantes por DPS
    - Mejor integración con GuardianEnhanced
]]--

if not WCS_BrainCombatCache then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Guardian Cache Ext]|r ERROR: WCS_BrainCombatCache no encontrado")
    return
end

local Cache = WCS_BrainCombatCache

-- ============================================================================
-- UTILIDADES LUA 5.0
-- ============================================================================
local function getTime()
    return GetTime and GetTime() or 0
end

local function tableCount(t)
    if not t then return 0 end
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

-- ============================================================================
-- EXTENSIÓN: TRACKING MULTI-UNIDAD DE AMENAZA
-- ============================================================================

-- Agregar tracking de unidades al sistema de amenaza existente
if not Cache.Threat.units then
    Cache.Threat.units = {}
end

-- Registrar amenaza para una unidad específica
function Cache.Threat:RegisterUnit(unitID, threatAmount)
    if not unitID then return end
    
    if not self.units[unitID] then
        self.units[unitID] = {
            threat = 0,
            lastUpdate = 0,
            isUnderAttack = false,
            lastHP = 0,
            hpHistory = {}
        }
    end
    
    self.units[unitID].threat = (self.units[unitID].threat or 0) + threatAmount
    self.units[unitID].lastUpdate = getTime()
end

-- Obtener amenaza de una unidad
function Cache.Threat:GetUnitThreat(unitID)
    if not unitID or not self.units[unitID] then return 0 end
    return self.units[unitID].threat or 0
end

-- Marcar unidad como bajo ataque
function Cache.Threat:MarkUnitUnderAttack(unitID, isUnderAttack)
    if not unitID then return end
    
    if not self.units[unitID] then
        self.units[unitID] = {
            threat = 0,
            lastUpdate = 0,
            isUnderAttack = false,
            lastHP = 0,
            hpHistory = {}
        }
    end
    
    self.units[unitID].isUnderAttack = isUnderAttack
    self.units[unitID].lastUpdate = getTime()
end

-- Verificar si unidad está bajo ataque
function Cache.Threat:IsUnitUnderAttack(unitID)
    if not unitID or not self.units[unitID] then return false end
    
    -- Expirar flag después de 3 segundos
    local now = getTime()
    if now - self.units[unitID].lastUpdate > 3 then
        self.units[unitID].isUnderAttack = false
    end
    
    return self.units[unitID].isUnderAttack
end

-- Actualizar HP de unidad y detectar si está siendo atacado
function Cache.Threat:UpdateUnitHP(unitID)
    if not unitID or not UnitExists(unitID) then return end
    
    if not self.units[unitID] then
        self.units[unitID] = {
            threat = 0,
            lastUpdate = 0,
            isUnderAttack = false,
            lastHP = 0,
            hpHistory = {}
        }
    end
    
    local currentHP = UnitHealth(unitID) or 0
    local lastHP = self.units[unitID].lastHP or currentHP
    
    -- Guardar en historial
    table.insert(self.units[unitID].hpHistory, {
        time = getTime(),
        hp = currentHP
    })
    
    -- Limitar historial a 5 entradas
    local historyCount = tableCount(self.units[unitID].hpHistory)
    if historyCount > 5 then
        table.remove(self.units[unitID].hpHistory, 1)
    end
    
    -- Detectar si está perdiendo HP (siendo atacado)
    if lastHP > currentHP and (lastHP - currentHP) > 0 then
        self:MarkUnitUnderAttack(unitID, true)
    end
    
    self.units[unitID].lastHP = currentHP
    self.units[unitID].lastUpdate = getTime()
end

-- ============================================================================
-- NUEVO: CACHE DE SALUD DE ALIADOS
-- ============================================================================

Cache.AllyHealth = Cache.AllyHealth or {
    units = {}
}

-- Actualizar salud de aliado
function Cache.AllyHealth:Update(unitID)
    if not unitID or not UnitExists(unitID) then return end
    
    local now = getTime()
    local health = UnitHealth(unitID) or 0
    local healthMax = UnitHealthMax(unitID) or 1
    
    if not self.units[unitID] then
        self.units[unitID] = {
            healthHistory = {},
            dpsReceived = 0,
            lastUpdate = 0
        }
    end
    
    -- Guardar en historial
    table.insert(self.units[unitID].healthHistory, {
        time = now,
        health = health,
        healthMax = healthMax
    })
    
    -- Limitar historial a 10 entradas
    local historyCount = tableCount(self.units[unitID].healthHistory)
    if historyCount > 10 then
        table.remove(self.units[unitID].healthHistory, 1)
    end
    
    -- Calcular DPS recibido
    historyCount = tableCount(self.units[unitID].healthHistory)
    if historyCount >= 3 then
        local oldest = self.units[unitID].healthHistory[1]
        local newest = self.units[unitID].healthHistory[historyCount]
        
        local timeDiff = newest.time - oldest.time
        local healthDiff = oldest.health - newest.health
        
        if timeDiff > 0 and healthDiff > 0 then
            self.units[unitID].dpsReceived = healthDiff / timeDiff
        else
            self.units[unitID].dpsReceived = 0
        end
    end
    
    self.units[unitID].lastUpdate = now
    
    -- También actualizar en Threat cache
    Cache.Threat:UpdateUnitHP(unitID)
end

-- Obtener DPS recibido por aliado
function Cache.AllyHealth:GetDPSReceived(unitID)
    if not unitID or not self.units[unitID] then return 0 end
    return self.units[unitID].dpsReceived or 0
end

-- Verificar si aliado está perdiendo salud rápidamente
function Cache.AllyHealth:IsLosingHealthFast(unitID, threshold)
    threshold = threshold or 100  -- DPS threshold
    local dps = self:GetDPSReceived(unitID)
    return dps > threshold
end

-- Limpiar datos antiguos
function Cache.AllyHealth:Cleanup()
    local now = getTime()
    local toRemove = {}
    
    for unitID, data in pairs(self.units) do
        if now - data.lastUpdate > 10 then
            table.insert(toRemove, unitID)
        end
    end
    
    for i = 1, table.getn(toRemove) do
        local unitID = toRemove[i]
        self.units[unitID] = nil
    end
end

-- ============================================================================
-- NUEVO: CACHE DE ATACANTES
-- ============================================================================

Cache.Attackers = Cache.Attackers or {
    victims = {}
}

-- Registrar atacante
function Cache.Attackers:Register(victimUnitID, attackerName)
    if not victimUnitID or not attackerName then return end
    
    if not self.victims[victimUnitID] then
        self.victims[victimUnitID] = {
            attackers = {},
            lastAttack = 0
        }
    end
    
    local now = getTime()
    self.victims[victimUnitID].attackers[attackerName] = now
    self.victims[victimUnitID].lastAttack = now
end

-- Obtener atacantes de una víctima
function Cache.Attackers:GetAttackers(victimUnitID)
    if not victimUnitID or not self.victims[victimUnitID] then return {} end
    
    local now = getTime()
    local result = {}
    
    for attackerName, lastSeen in pairs(self.victims[victimUnitID].attackers) do
        -- Solo incluir atacantes vistos en los últimos 5 segundos
        if now - lastSeen < 5 then
            table.insert(result, attackerName)
        end
    end
    
    return result
end

-- Verificar si unidad tiene atacantes activos
function Cache.Attackers:HasActiveAttackers(victimUnitID)
    local attackers = self:GetAttackers(victimUnitID)
    return tableCount(attackers) > 0
end

-- Limpiar datos antiguos
function Cache.Attackers:Cleanup()
    local now = getTime()
    local toRemove = {}
    
    for victimUnitID, data in pairs(self.victims) do
        -- Limpiar atacantes antiguos
        for attackerName, lastSeen in pairs(data.attackers) do
            if now - lastSeen > 10 then
                data.attackers[attackerName] = nil
            end
        end
        
        -- Si no hay atacantes, marcar para remover
        local hasAttackers = false
        for k, v in pairs(data.attackers) do
            hasAttackers = true
            break
        end
        
        if not hasAttackers and now - data.lastAttack > 10 then
            table.insert(toRemove, victimUnitID)
        end
    end
    
    for i = 1, table.getn(toRemove) do
        local victimUnitID = toRemove[i]
        self.victims[victimUnitID] = nil
    end
end

-- ============================================================================
-- INTEGRACIÓN CON LIMPIEZA PERIÓDICA
-- ============================================================================

-- Guardar función original de limpieza
local OriginalPeriodicCleanup = Cache.PeriodicCleanup

-- Extender limpieza periódica
function Cache:PeriodicCleanup()
    -- Llamar limpieza original
    if OriginalPeriodicCleanup then
        OriginalPeriodicCleanup(self)
    end
    
    -- Limpiar extensiones
    if self.AllyHealth and self.AllyHealth.Cleanup then
        self.AllyHealth:Cleanup()
    end
    
    if self.Attackers and self.Attackers.Cleanup then
        self.Attackers:Cleanup()
    end
end

-- ============================================================================
-- FUNCIONES DE AYUDA PARA MODO GUARDIÁN
-- ============================================================================

-- Obtener estado completo de un aliado
function Cache:GetGuardianAllyStatus(unitID)
    if not unitID or not UnitExists(unitID) then return nil end
    
    return {
        threat = self.Threat:GetUnitThreat(unitID),
        isUnderAttack = self.Threat:IsUnitUnderAttack(unitID),
        dpsReceived = self.AllyHealth:GetDPSReceived(unitID),
        isLosingHealthFast = self.AllyHealth:IsLosingHealthFast(unitID, 100),
        attackers = self.Attackers:GetAttackers(unitID),
        hasActiveAttackers = self.Attackers:HasActiveAttackers(unitID)
    }
end

-- Actualizar todo el estado de un aliado (llamar periódicamente)
function Cache:UpdateGuardianAlly(unitID)
    if not unitID or not UnitExists(unitID) then return end
    
    -- Actualizar salud (esto también actualiza HP en Threat)
    self.AllyHealth:Update(unitID)
    
    -- Detectar atacantes basándose en cambios de HP
    if self.Threat:IsUnitUnderAttack(unitID) then
        -- Intentar identificar atacante
        local guardianTarget = unitID .. "target"
        if UnitExists(guardianTarget) and UnitCanAttack("player", guardianTarget) then
            local attackerName = UnitName(guardianTarget)
            if attackerName then
                self.Attackers:Register(unitID, attackerName)
            end
        end
    end
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFAA[Guardian Cache Ext]|r Extensiones de CombatCache cargadas v1.0.0")

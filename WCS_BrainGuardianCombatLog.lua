--[[
    WCS_BrainGuardianCombatLog.lua
    Sistema de Detección de Atacantes via CombatLog
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.0.0
    
    Este archivo implementa un sistema de detección de atacantes en tiempo real
    usando el CombatLog para mejorar el modo Guardián.
]]--

if not WCS_BrainPetAI then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Guardian CombatLog]|r ERROR: WCS_BrainPetAI no encontrado")
    return
end

local PetAI = WCS_BrainPetAI

-- ============================================================================
-- SISTEMA DE TRACKING DE ATACANTES
-- ============================================================================

PetAI.GuardianCombatLog = {
    enabled = false,
    guardianTargetName = nil,
    guardianUnitID = nil,
    attackers = {},  -- { [attackerName] = { dps, damage, hits, firstSeen, lastSeen } }
    totalDamageReceived = 0,
    combatStartTime = 0,
    debugMode = false  -- Debug desactivado por defecto (activar con /gdebug)
}

local GCL = PetAI.GuardianCombatLog

-- ============================================================================
-- FUNCIONES DE TRACKING
-- ============================================================================

-- Registrar un ataque
function GCL:RegisterAttack(attackerName, damage)
    if not attackerName then return end
    
    local now = GetTime()
    damage = damage or 0
    
    -- Inicializar atacante si no existe
    if not self.attackers[attackerName] then
        self.attackers[attackerName] = {
            damage = 0,
            hits = 0,
            dps = 0,
            firstSeen = now,
            lastSeen = now
        }
    end
    
    local attacker = self.attackers[attackerName]
    attacker.damage = attacker.damage + damage
    attacker.hits = attacker.hits + 1
    attacker.lastSeen = now
    
    -- Calcular DPS
    local timeSinceFirst = now - attacker.firstSeen
    if timeSinceFirst > 0 then
        attacker.dps = attacker.damage / timeSinceFirst
    end
    
    self.totalDamageReceived = self.totalDamageReceived + damage
    
    -- Marcar al aliado como bajo ataque
    if WCS_BrainCombatCache and WCS_BrainCombatCache.Threat then
        WCS_BrainCombatCache.Threat:MarkUnitUnderAttack(self.guardianUnitID, true)
    end
end

-- Obtener lista de atacantes ordenada por DPS
function GCL:GetAttackers(sortByDPS)
    local result = {}
    local now = GetTime()
    
    for name, data in pairs(self.attackers) do
        -- Solo incluir atacantes vistos en los últimos 5 segundos
        if now - data.lastSeen < 5 then
            table.insert(result, {
                name = name,
                dps = data.dps,
                damage = data.damage,
                hits = data.hits,
                lastSeen = data.lastSeen
            })
        end
    end
    
    -- Ordenar por DPS si se solicita
    if sortByDPS and table.getn(result) > 1 then
        table.sort(result, function(a, b)
            return a.dps > b.dps
        end)
    end
    
    return result
end

-- Obtener el atacante más peligroso
function GCL:GetMostDangerous()
    local attackers = self:GetAttackers(true)
    if table.getn(attackers) > 0 then
        return attackers[1].name, attackers[1].dps
    end
    return nil, 0
end

-- Limpiar atacantes antiguos
function GCL:Cleanup()
    local now = GetTime()
    local toRemove = {}
    
    for name, data in pairs(self.attackers) do
        if now - data.lastSeen > 10 then
            table.insert(toRemove, name)
        end
    end
    
    for i = 1, table.getn(toRemove) do
        self.attackers[toRemove[i]] = nil
    end
end

-- Resetear todo
function GCL:Reset()
    self.attackers = {}
    self.totalDamageReceived = 0
    self.combatStartTime = 0
end

-- ============================================================================
-- FRAME DE EVENTOS DE COMBATE
-- ============================================================================

local GuardianCombatFrame = CreateFrame("Frame")

-- Parsear mensaje de combate
local function ParseCombatMessage(message)
    if not message then return nil, nil, nil end
    
    local attackerName, victimName, damage
    
    -- Patrón 1: "Mob hits Player for X."
    attackerName, victimName, damage = string.gfind(message, "(.+) hits (.+) for (%d+)")()
    if attackerName then return attackerName, victimName, tonumber(damage) end
    
    -- Patrón 2: "Mob crits Player for X."
    attackerName, victimName, damage = string.gfind(message, "(.+) crits (.+) for (%d+)")()
    if attackerName then return attackerName, victimName, tonumber(damage) end
    
    -- Patrón 3: "Mob's Spell hits Player for X."
    attackerName, victimName, damage = string.gfind(message, "(.+)'s .+ hits (.+) for (%d+)")()
    if attackerName then return attackerName, victimName, tonumber(damage) end
    
    -- Patrón 4: "Mob's Spell crits Player for X."
    attackerName, victimName, damage = string.gfind(message, "(.+)'s .+ crits (.+) for (%d+)")()
    if attackerName then return attackerName, victimName, tonumber(damage) end
    
    -- Patrón 5: "Player suffers X damage from Mob's Spell."
    victimName, damage, attackerName = string.gfind(message, "(.+) suffers (%d+) .+ damage from (.+)'s")()
    if attackerName then return attackerName, victimName, tonumber(damage) end
    
    -- Patrón 6: "Mob hits Player." (sin daño)
    attackerName, victimName = string.gfind(message, "(.+) hits (.+)%.")()
    if attackerName then return attackerName, victimName, 0 end
    
    return nil, nil, nil
end

-- Handler de eventos
GuardianCombatFrame:SetScript("OnEvent", function()
    if not GCL.enabled or not GCL.guardianTargetName then return end
    
    -- Verificar que sea un evento de combate relevante
    if event ~= "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS" and 
       event ~= "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES" and
       event ~= "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" and
       event ~= "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" and
       event ~= "CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS" and
       event ~= "CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES" and
       event ~= "CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE" and
       event ~= "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE" and
       event ~= "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE" and
       event ~= "CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE" and
       event ~= "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" and
       event ~= "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE" then
        return
    end
    
    -- Parsear mensaje
    local attackerName, victimName, damage = ParseCombatMessage(arg1)
    
    if not attackerName or not victimName then return end
    
    -- Debug: Mostrar TODOS los mensajes de combate
    if GCL.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFFF00[Debug]|r Evento: %s", event or "nil"))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFFF00[Debug]|r Mensaje: %s", arg1 or "nil"))
        if attackerName and victimName then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFFF00[Debug]|r Parseado: %s -> %s (%d)", attackerName, victimName, damage or 0))
        end
    end
    
    -- Debug: Comparar nombres
    if GCL.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFFF00[Debug]|r Comparando: '%s' vs '%s'", victimName, GCL.guardianTargetName or "nil"))
    end
    
    -- Verificar si la víctima es el guardián asignado
    if victimName and GCL.guardianTargetName and victimName == GCL.guardianTargetName then
        GCL:RegisterAttack(attackerName, damage)
        
        -- Confirmación
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000[Guardian]|r %s atacó a %s por %d", 
            attackerName, victimName, damage or 0))
    end
end)

-- ============================================================================
-- FUNCIONES PÚBLICAS
-- ============================================================================

-- Activar tracking de combate
function GCL:Enable(guardianTargetName, guardianUnitID)
    if not guardianTargetName then return false end
    
    self.guardianTargetName = guardianTargetName
    self.guardianUnitID = guardianUnitID
    
    if not self.enabled then
        -- Registrar eventos (criaturas)
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS")
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES")
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES")
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE")
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE")
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
        -- Registrar eventos (jugadores hostiles)
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS")
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES")
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
        GuardianCombatFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
        
        self.enabled = true
        self.combatStartTime = GetTime()
        
        PetAI:Print(string.format("|cFF00FF00[Guardián]|r CombatLog activado para %s", guardianTargetName))
    end
    
    return true
end

-- Desactivar tracking
function GCL:Disable()
    if self.enabled then
        GuardianCombatFrame:UnregisterAllEvents()
        self.enabled = false
        self.guardianTargetName = nil
        self.guardianUnitID = nil
        self:Reset()
        
        PetAI:Print("|cFFFF6600[Guardián]|r CombatLog desactivado")
    end
end

-- ============================================================================
-- INTEGRACIÓN CON PETAI
-- ============================================================================

-- Hook para cuando se asigna un guardián
local OriginalSetGuardianTarget = PetAI.SetGuardianTarget

function PetAI:SetGuardianTarget(targetName)
    -- Llamar función original
    if OriginalSetGuardianTarget then
        OriginalSetGuardianTarget(self, targetName)
    else
        self.GuardianTarget = targetName
    end
    
    -- Activar CombatLog si hay un target
    if targetName and targetName ~= "" then
        local guardianUnit = self:FindGuardianUnit()
        if guardianUnit then
            GCL:Enable(targetName, guardianUnit)
        end
    else
        GCL:Disable()
    end
end

-- Timer de limpieza
local cleanupTimer = 0
local cleanupInterval = 5  -- Limpiar cada 5 segundos

local CleanupFrame = CreateFrame("Frame")
CleanupFrame:SetScript("OnUpdate", function()
    if not GCL.enabled then return end
    
    cleanupTimer = cleanupTimer + arg1
    if cleanupTimer >= cleanupInterval then
        GCL:Cleanup()
        cleanupTimer = 0
    end
end)

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFAA[Guardian CombatLog]|r Sistema de detección de atacantes cargado v1.0.0")

-- Comando /gdebug
SLASH_GUARDIANDEBUG1 = "/gdebug"
SlashCmdList["GUARDIANDEBUG"] = function(msg)
    GCL.debugMode = not GCL.debugMode
    local status = GCL.debugMode and "ACTIVADO" or "DESACTIVADO"
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FFAA[Guardian]|r Modo debug %s", status))
end

-- Comando /gstats
SLASH_GUARDIANSTATS1 = "/gstats"
SLASH_GUARDIANSTATS2 = "/guardianstats"
SlashCmdList["GUARDIANSTATS"] = function(msg)
    if not GCL.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Guardian]|r Sistema no activo. Usa /petguard [nombre]")
        return
    end
    local attackers = GCL:GetAttackers(true)
    local now = GetTime()
    local combatDuration = now - GCL.combatStartTime
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFAA=== Estadisticas del Guardian ===")
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Protegiendo a: |cFFFFFF00%s|r", GCL.guardianTargetName or "Nadie"))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Duracion: %.1f seg | Dano total: |cFFFF0000%d|r", combatDuration, GCL.totalDamageReceived))
    local avgDPS = combatDuration > 0 and (GCL.totalDamageReceived / combatDuration) or 0
    DEFAULT_CHAT_FRAME:AddMessage(string.format("DPS promedio: |cFFFF6600%.1f|r | Atacantes: |cFFFF6600%d|r", avgDPS, table.getn(attackers)))
    if table.getn(attackers) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFAA--- Atacantes (por DPS) ---")
        for i = 1, table.getn(attackers) do
            local att = attackers[i]
            local status = (now - att.lastSeen < 2) and "|cFFFF0000[ATACANDO]|r" or "|cFF888888[Inactivo]|r"
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %d. %s %s", i, att.name, status))
            DEFAULT_CHAT_FRAME:AddMessage(string.format("     DPS: %.1f | Dano: %d | Hits: %d", att.dps, att.damage, att.hits))
        end
    end
end
DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFAA[Guardian CombatLog]|r Usa /gstats para estadisticas")


--[[
    WCS_BrainPetAI_CoordinationEnhanced.lua
    Mejoras de Coordinación entre Jugador y Mascota
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.0.0
    
    Este archivo extiende WCS_BrainPetAI con mejor coordinación
    con las acciones del jugador detectadas por CombatController.
]]--

if not WCS_BrainPetAI then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAI Coordination]|r ERROR: WCS_BrainPetAI no encontrado")
    return
end

local PetAI = WCS_BrainPetAI

-- ============================================================================
-- VARIABLES DE COORDINACIÓN EXTENDIDAS
-- ============================================================================

-- Inicializar variables si no existen
PetAI.lastPlayerFear = PetAI.lastPlayerFear or 0
PetAI.playerInDanger = PetAI.playerInDanger or false
PetAI.playerDangerTime = PetAI.playerDangerTime or 0
PetAI.receivingHealing = PetAI.receivingHealing or false
PetAI.healingStartTime = PetAI.healingStartTime or 0
PetAI.playerDraining = PetAI.playerDraining or false
PetAI.drainingStartTime = PetAI.drainingStartTime or 0
PetAI.playerUsedLifeTap = PetAI.playerUsedLifeTap or false
PetAI.lifeTapTime = PetAI.lifeTapTime or 0
PetAI.playerExecuting = PetAI.playerExecuting or false
PetAI.executingTime = PetAI.executingTime or 0
PetAI.playerUsedHealthstone = PetAI.playerUsedHealthstone or false
PetAI.healthstoneTime = PetAI.healthstoneTime or 0

-- ============================================================================
-- HOOK MEJORADO: OnPlayerAction
-- ============================================================================

-- Guardar la función original si existe
PetAI.OnPlayerAction_Original = PetAI.OnPlayerAction

-- Nueva función mejorada
function PetAI:OnPlayerAction(playerDecision)
    if not playerDecision then return end
    
    local spell = playerDecision.spell
    local now = GetTime()
    
    -- Fear: La mascota debe evitar atacar al target feared
    if spell == "Fear" or spell == "Howl of Terror" then
        self.lastPlayerFear = now
        if self.debug then
            self:DebugPrint("[Coordinación] Jugador usó " .. spell .. " - Evitando target feared")
        end
    
    -- Death Coil: Jugador en peligro, mascota debe ser más defensiva
    elseif spell == "Death Coil" then
        self.playerInDanger = true
        self.playerDangerTime = now
        if self.debug then
            self:DebugPrint("[Coordinación] Jugador en peligro - Modo defensivo temporal")
        end
    
    -- Health Funnel: Mascota recibiendo curación, puede ser más agresiva
    elseif spell == "Health Funnel" then
        self.receivingHealing = true
        self.healingStartTime = now
        if self.debug then
            self:DebugPrint("[Coordinación] Recibiendo Health Funnel - Modo agresivo temporal")
        end
    
    -- Drain Life/Soul: Jugador recuperando vida, mascota puede tanquear
    elseif spell == "Drain Life" or spell == "Drain Soul" then
        self.playerDraining = true
        self.drainingStartTime = now
        if self.debug then
            self:DebugPrint("[Coordinación] Jugador usando " .. spell .. " - Mascota tanqueando")
        end
    
    -- Life Tap: Jugador sacrificando vida por mana
    elseif spell == "Life Tap" then
        self.playerUsedLifeTap = true
        self.lifeTapTime = now
        if self.debug then
            self:DebugPrint("[Coordinación] Jugador usó Life Tap - Monitoreando salud")
        end
    
    -- Shadowburn: Jugador intentando ejecutar, mascota debe ayudar
    elseif spell == "Shadowburn" then
        self.playerExecuting = true
        self.executingTime = now
        if self.debug then
            self:DebugPrint("[Coordinación] Jugador ejecutando con Shadowburn - Maximizando DPS")
        end
    
    -- Healthstone: Jugador usó healthstone, situación crítica
    elseif spell == "Healthstone" then
        self.playerUsedHealthstone = true
        self.healthstoneTime = now
        if self.debug then
            self:DebugPrint("[Coordinación] Jugador usó Healthstone - Situación crítica")
        end
    end
end

-- ============================================================================
-- FUNCIONES DE UTILIDAD PARA COORDINACIÓN
-- ============================================================================

-- Función auxiliar para verificar estados temporales (reduce duplicación)
function PetAI:CheckTimedState(flagName, timeName, duration)
    if not self[flagName] then return false end
    
    local now = GetTime()
    if now - self[timeName] > duration then
        self[flagName] = false
        return false
    end
    
    return true
end

-- Verificar si el jugador tiene Soulstone activa (buff)
function PetAI:PlayerHasSoulstone()
    local i = 1
    while true do
        local buffTexture = UnitBuff("player", i)
        if not buffTexture then break end
        
        -- Soulstone Resurrection tiene texture específica
        -- En Vanilla: Interface\\Icons\\Spell_Shadow_SoulGem
        local lowerTexture = string.lower(buffTexture)
        if string.find(lowerTexture, "soulgem") or 
           string.find(lowerTexture, "soulstone") or
           string.find(lowerTexture, "alma") then
            return true
        end
        i = i + 1
    end
    return false
end

-- Verificar si el jugador tiene Healthstone en el inventario
function PetAI:PlayerHasHealthstone()
    -- Buscar en todas las bolsas (0 = backpack, 1-4 = bags)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink then
                    -- En Vanilla WoW, el link tiene formato: |cffffffff|Hitem:id|h[Nombre]|h|r
                    -- Buscar "Healthstone" (EN) o "Piedra de salud" (ES) en el link
                    local lowerLink = string.lower(itemLink)
                    if string.find(lowerLink, "healthstone") or string.find(lowerLink, "piedra de salud") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Verificar si el jugador está en peligro (salud baja O Death Coil reciente)
function PetAI:IsPlayerInDanger()
    -- Verificar salud del jugador
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    if health and maxHealth and maxHealth > 0 then
        local healthPercent = (health / maxHealth) * 100
        if healthPercent < 40 then
            return true
        end
    end
    
    -- También verificar si usó Death Coil recientemente
    return self:CheckTimedState("playerInDanger", "playerDangerTime", 10)
end

-- Verificar si la mascota está recibiendo Health Funnel
function PetAI:IsReceivingHealing()
    return self:CheckTimedState("receivingHealing", "healingStartTime", 10)
end

-- Verificar si el jugador está usando Drain Life/Soul
function PetAI:IsPlayerDraining()
    return self:CheckTimedState("playerDraining", "drainingStartTime", 5)
end

-- Verificar si el jugador usó Life Tap recientemente
function PetAI:PlayerUsedLifeTapRecently()
    return self:CheckTimedState("playerUsedLifeTap", "lifeTapTime", 5)
end

-- Verificar si el jugador está ejecutando (target bajo de vida O Shadowburn reciente)
function PetAI:IsPlayerExecuting()
    -- Verificar salud del target
    if UnitExists("target") and not UnitIsDead("target") then
        local targetHealth = UnitHealth("target")
        local targetMaxHealth = UnitHealthMax("target")
        if targetHealth and targetMaxHealth and targetMaxHealth > 0 then
            local targetHealthPercent = (targetHealth / targetMaxHealth) * 100
            if targetHealthPercent < 20 then
                return true
            end
        end
    end
    
    -- También verificar si usó Shadowburn recientemente
    return self:CheckTimedState("playerExecuting", "executingTime", 3)
end

-- Verificar si el jugador usó Healthstone recientemente
function PetAI:PlayerUsedHealthstoneRecently()
    return self:CheckTimedState("playerUsedHealthstone", "healthstoneTime", 10)
end

-- Verificar si el jugador usó Fear recientemente
function PetAI:PlayerUsedFearRecently()
    local now = GetTime()
    -- Fear dura hasta 20 segundos
    return (now - self.lastPlayerFear) < 20
end

-- ============================================================================
-- AJUSTES DE COMPORTAMIENTO BASADOS EN COORDINACIÓN
-- ============================================================================

-- Obtener modificador de agresividad basado en estado del jugador
function PetAI:GetAggressivenessModifier()
    local modifier = 1.0
    
    -- Si el jugador está en peligro, reducir agresividad
    if self:IsPlayerInDanger() then
        modifier = modifier * 0.5
    end
    
    -- Si recibiendo Health Funnel, aumentar agresividad
    if self:IsReceivingHealing() then
        modifier = modifier * 1.5
    end
    
    -- Si el jugador está usando Drain, la mascota debe tanquear
    if self:IsPlayerDraining() then
        modifier = modifier * 0.7
    end
    
    -- Si el jugador usó Healthstone, situación crítica
    if self:PlayerUsedHealthstoneRecently() then
        modifier = modifier * 0.3
    end
    
    -- Si el jugador está ejecutando, maximizar DPS
    if self:IsPlayerExecuting() then
        modifier = modifier * 1.8
    end
    
    -- Si el jugador tiene Soulstone, puede arriesgar más
    if self:PlayerHasSoulstone() then
        modifier = modifier * 1.2
    end
    
    -- Limitar el rango del modificador para evitar valores extremos
    -- Mínimo: 0.2 (muy defensivo), Máximo: 2.5 (muy agresivo)
    if modifier < 0.2 then modifier = 0.2 end
    if modifier > 2.5 then modifier = 2.5 end
    
    return modifier
end

-- Determinar si la mascota debe priorizar defensa
function PetAI:ShouldPrioritizeDefense()
    -- Priorizar defensa si:
    -- 1. Jugador en peligro
    -- 2. Jugador usó Healthstone recientemente
    -- 3. Jugador está usando Drain Life/Soul
    
    if self:IsPlayerInDanger() then return true end
    if self:PlayerUsedHealthstoneRecently() then return true end
    if self:IsPlayerDraining() then return true end
    
    return false
end

-- Determinar si la mascota debe priorizar ataque
function PetAI:ShouldPrioritizeAttack()
    -- Priorizar ataque si:
    -- 1. Recibiendo Health Funnel
    -- 2. Jugador ejecutando con Shadowburn
    -- 3. Jugador tiene Soulstone
    
    if self:IsReceivingHealing() then return true end
    if self:IsPlayerExecuting() then return true end
    if self:PlayerHasSoulstone() then return true end
    
    return false
end

-- ============================================================================
-- COMANDO DE DEBUG
-- ============================================================================

SLASH_PETCOORD1 = "/petcoord"
SlashCmdList["PETCOORD"] = function(msg)
    local cmd = string.lower(msg or "")
    
    if cmd == "status" or cmd == "" then
        PetAI:Print("=== Estado de Coordinación ===")
        PetAI:Print("Jugador en peligro: " .. (PetAI:IsPlayerInDanger() and "SÍ" or "NO"))
        PetAI:Print("Recibiendo curación: " .. (PetAI:IsReceivingHealing() and "SÍ" or "NO"))
        PetAI:Print("Jugador usando Drain: " .. (PetAI:IsPlayerDraining() and "SÍ" or "NO"))
        PetAI:Print("Life Tap reciente: " .. (PetAI:PlayerUsedLifeTapRecently() and "SÍ" or "NO"))
        PetAI:Print("Ejecutando target: " .. (PetAI:IsPlayerExecuting() and "SÍ" or "NO"))
        PetAI:Print("")
        PetAI:Print("=== Items/Buffs (Verificación en Tiempo Real) ===")
        PetAI:Print("Tiene Soulstone (buff): " .. (PetAI:PlayerHasSoulstone() and "SÍ" or "NO"))
        PetAI:Print("Tiene Healthstone (inventario): " .. (PetAI:PlayerHasHealthstone() and "SÍ" or "NO"))
        PetAI:Print("Usó Healthstone recientemente: " .. (PetAI:PlayerUsedHealthstoneRecently() and "SÍ" or "NO"))
        PetAI:Print("Fear reciente: " .. (PetAI:PlayerUsedFearRecently() and "SÍ" or "NO"))
        PetAI:Print("")
        PetAI:Print("Modificador de agresividad: " .. string.format("%.2f", PetAI:GetAggressivenessModifier()))
        PetAI:Print("Priorizar defensa: " .. (PetAI:ShouldPrioritizeDefense() and "SÍ" or "NO"))
        PetAI:Print("Priorizar ataque: " .. (PetAI:ShouldPrioritizeAttack() and "SÍ" or "NO"))
    elseif cmd == "reset" then
        PetAI.playerInDanger = false
        PetAI.receivingHealing = false
        PetAI.playerDraining = false
        PetAI.playerUsedLifeTap = false
        PetAI.playerExecuting = false
        PetAI.playerUsedHealthstone = false
        PetAI.lastPlayerFear = 0
        PetAI:Print("Estado de coordinación reseteado")
    else
        PetAI:Print("Comandos /petcoord:")
        PetAI:Print("  /petcoord status - Ver estado de coordinación")
        PetAI:Print("  /petcoord reset - Resetear estado")
    end
end

-- ============================================================================
-- SISTEMA DE EVENTOS PARA DETECTAR HECHIZOS DEL JUGADOR
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
eventFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
eventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
eventFrame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
eventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
eventFrame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
eventFrame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
eventFrame:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
eventFrame:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
eventFrame:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")

eventFrame:SetScript("OnEvent", function()
    local event = event
    local msg = arg1
    
    if not msg then return end
    
    local now = GetTime()
    
    -- Life Tap: "You gain X Mana from Life Tap" o "Life Tap" (EN) / "Transfusión de vida" (ES)
    if string.find(msg, "Life Tap") or string.find(msg, "Transfusi") or string.find(msg, "transfusi") then
        PetAI.playerUsedLifeTap = true
        PetAI.lifeTapTime = now
        if PetAI.debug then
            PetAI:DebugPrint("[Evento] Life Tap detectado")
        end
    end
    
    -- Shadowburn: "Your Shadowburn" (EN) / "Quemadura" (ES)
    if string.find(msg, "Shadowburn") or string.find(msg, "Quemadura") or string.find(msg, "quemadura") then
        PetAI.playerExecuting = true
        PetAI.executingTime = now
        if PetAI.debug then
            PetAI:DebugPrint("[Evento] Shadowburn detectado")
        end
    end
    
    -- Death Coil: "Your Death Coil" (EN) / "Espiral" (ES)
    if string.find(msg, "Death Coil") or string.find(msg, "Espiral") or string.find(msg, "espiral") then
        PetAI.playerInDanger = true
        PetAI.playerDangerTime = now
        if PetAI.debug then
            PetAI:DebugPrint("[Evento] Death Coil detectado - Jugador en peligro")
        end
    end
    
    -- Fear: "Your Fear" (EN) / "Miedo" (ES)
    if (string.find(msg, "Fear") or string.find(msg, "Miedo") or string.find(msg, "miedo")) and not string.find(msg, "Howl") and not string.find(msg, "Aullido") and not string.find(msg, "aullido") then
        PetAI.lastPlayerFear = now
        if PetAI.debug then
            PetAI:DebugPrint("[Evento] Fear detectado")
        end
    end
    
    -- Howl of Terror: (EN) / "Aullido" (ES)
    if string.find(msg, "Howl of Terror") or string.find(msg, "Aullido") or string.find(msg, "aullido") then
        PetAI.lastPlayerFear = now
        if PetAI.debug then
            PetAI:DebugPrint("[Evento] Howl of Terror detectado")
        end
    end
    
    -- Health Funnel: "Health Funnel" (EN) / "Canalizar" o "Embudo" (ES)
    if string.find(msg, "Health Funnel") or string.find(msg, "Canalizar") or string.find(msg, "canalizar") or string.find(msg, "Embudo") or string.find(msg, "embudo") then
        PetAI.receivingHealing = true
        PetAI.healingStartTime = now
        if PetAI.debug then
            PetAI:DebugPrint("[Evento] Health Funnel detectado")
        end
    end
    
    -- Drain Life: "Drain Life" (EN) / "Drenar vida" (ES)
    if string.find(msg, "Drain Life") or string.find(msg, "Drenar vida") or string.find(msg, "drenar vida") then
        PetAI.playerDraining = true
        PetAI.drainingStartTime = now
        if PetAI.debug then
            PetAI:DebugPrint("[Evento] Drain Life detectado")
        end
    end
    
    -- Drain Soul: "Drain Soul" (EN) / "Drenar alma" (ES)
    if string.find(msg, "Drain Soul") or string.find(msg, "Drenar alma") or string.find(msg, "drenar alma") then
        PetAI.playerDraining = true
        PetAI.drainingStartTime = now
        if PetAI.debug then
            PetAI:DebugPrint("[Evento] Drain Soul detectado")
        end
    end
    
    -- Healthstone: (EN) / "Piedra de salud" (ES)
    if string.find(msg, "Healthstone") or string.find(msg, "health stone") or string.find(msg, "Piedra de salud") or string.find(msg, "piedra de salud") then
        PetAI.playerUsedHealthstone = true
        PetAI.healthstoneTime = now
        if PetAI.debug then
            PetAI:DebugPrint("[Evento] Healthstone detectado")
        end
    end
end)

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAI Coordination]|r Sistema de coordinación mejorado cargado - Usa /petcoord")
DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAI Coordination]|r Sistema de eventos activo - Detectando hechizos en tiempo real")

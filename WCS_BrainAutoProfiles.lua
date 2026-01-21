-- WCS_BrainAutoProfiles.lua
-- Sistema de Perfiles Automáticos para WCS_Brain
-- Detecta la situación del jugador y cambia el perfil automáticamente

WCS_BrainAutoProfiles = {}

-- Variables locales
local currentSituation = "SOLO"
local lastCheck = 0
local pendingProfile = nil
local pendingTime = 0
local isChanging = false

-- Configuración por defecto
local defaultConfig = {
    enabled = false, -- Desactivado por defecto para no sorprender al usuario
    delay = 3, -- Segundos antes de cambiar perfil
    notifications = true,
    checkInterval = 2, -- Chequear cada 2 segundos
    rules = {
        {
            name = "Raid",
            priority = 1,
            condition = "IN_RAID",
            profile = "Affliction Raid",
            enabled = true
        },
        {
            name = "Dungeon",
            priority = 2,
            condition = "IN_DUNGEON",
            profile = "Destruction Dungeon",
            enabled = true
        },
        {
            name = "Battleground",
            priority = 3,
            condition = "IN_BATTLEGROUND",
            profile = "Destruction PvP",
            enabled = true
        },
        {
            name = "Party",
            priority = 4,
            condition = "IN_PARTY",
            profile = "Affliction Solo",
            enabled = true
        },
        {
            name = "Ciudad",
            priority = 5,
            condition = "IN_CITY",
            profile = "Affliction Solo",
            enabled = false -- Desactivado por defecto
        },
        {
            name = "Solo",
            priority = 6,
            condition = "SOLO",
            profile = "Affliction Solo",
            enabled = true
        }
    }
}

-- Inicialización
function WCS_BrainAutoProfiles:Initialize()
    -- Crear configuración si no existe
    if not WCS_BrainSaved then
        WCS_BrainSaved = {}
    end
    
    if not WCS_BrainSaved.autoProfiles then
        WCS_BrainSaved.autoProfiles = defaultConfig
    end
    
    -- Registrar eventos
    self:RegisterEvents()
    
    -- Mensaje de inicio
    if WCS_BrainSaved.autoProfiles.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Brain]|r Sistema de Perfiles Automáticos activado")
    end
end

-- Registrar eventos
function WCS_BrainAutoProfiles:RegisterEvents()
    local frame = CreateFrame("Frame", "WCS_BrainAutoProfilesFrame")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
    frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
    
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            WCS_BrainAutoProfiles:OnPlayerEnteringWorld()
        else
            WCS_BrainAutoProfiles:OnSituationChanged()
        end
    end)
    
    -- OnUpdate para chequeo periódico
    frame:SetScript("OnUpdate", function()
        WCS_BrainAutoProfiles:OnUpdate(arg1)
    end)
end

-- OnUpdate
function WCS_BrainAutoProfiles:OnUpdate(elapsed)
    if not WCS_BrainSaved.autoProfiles.enabled then
        return
    end
    
    lastCheck = lastCheck + elapsed
    
    -- Chequear cada X segundos
    if lastCheck >= WCS_BrainSaved.autoProfiles.checkInterval then
        lastCheck = 0
        self:CheckSituation()
    end
    
    -- Manejar cambio pendiente
    if pendingProfile then
        pendingTime = pendingTime + elapsed
        if pendingTime >= WCS_BrainSaved.autoProfiles.delay then
            self:ApplyPendingProfile()
        end
    end
end

-- Al entrar al mundo
function WCS_BrainAutoProfiles:OnPlayerEnteringWorld()
    -- Esperar 2 segundos antes de evaluar (dar tiempo a que cargue todo)
    local frame = CreateFrame("Frame")
    local elapsed = 0
    frame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= 2 then
            frame:SetScript("OnUpdate", nil)
            WCS_BrainAutoProfiles:CheckSituation()
        end
    end)
end

-- Cuando cambia la situación
function WCS_BrainAutoProfiles:OnSituationChanged()
    if not WCS_BrainSaved.autoProfiles.enabled then
        return
    end
    
    -- Chequear inmediatamente
    self:CheckSituation()
end

-- Chequear situación actual
function WCS_BrainAutoProfiles:CheckSituation()
    if isChanging then
        return -- Evitar chequeos mientras se está cambiando
    end
    
    local newSituation = self:DetectSituation()
    
    if newSituation ~= currentSituation then
        currentSituation = newSituation
        self:EvaluateRules()
    end
end

-- Detectar situación actual
function WCS_BrainAutoProfiles:DetectSituation()
    -- Prioridad: Raid > Dungeon > BG > Party > City > Solo
    
    -- Raid
    if GetNumRaidMembers() > 0 then
        return "IN_RAID"
    end
    
    -- Dungeon/Instancia
    local inInstance, instanceType = IsInInstance()
    if inInstance then
        if instanceType == "pvp" then
            return "IN_BATTLEGROUND"
        elseif instanceType == "party" or instanceType == "raid" then
            return "IN_DUNGEON"
        end
    end
    
    -- Party
    if GetNumPartyMembers() > 0 then
        return "IN_PARTY"
    end
    
    -- Ciudad (detectar por zona)
    local zone = GetZoneText()
    if self:IsCity(zone) then
        return "IN_CITY"
    end
    
    -- Solo
    return "SOLO"
end

-- Verificar si una zona es ciudad
function WCS_BrainAutoProfiles:IsCity(zone)
    local cities = {
        -- Horde
        ["Orgrimmar"] = true,
        ["Thunder Bluff"] = true,
        ["Undercity"] = true,
        -- Alliance
        ["Stormwind City"] = true,
        ["Ironforge"] = true,
        ["Darnassus"] = true,
        -- Neutral
        ["Shattrath City"] = true,
        ["Dalaran"] = true,
        ["Booty Bay"] = true,
        ["Gadgetzan"] = true,
        ["Everlook"] = true,
        ["Ratchet"] = true
    }
    
    return cities[zone] == true
end

-- Evaluar reglas y determinar perfil a usar
function WCS_BrainAutoProfiles:EvaluateRules()
    local config = WCS_BrainSaved.autoProfiles
    local bestRule = nil
    local bestPriority = 999
    
    -- Buscar la regla con mayor prioridad que coincida
    for i = 1, table.getn(config.rules) do
        local rule = config.rules[i]
        if rule.enabled and rule.profile and rule.profile ~= "" and self:CheckCondition(rule.condition) then
            if rule.priority < bestPriority then
                bestPriority = rule.priority
                bestRule = rule
            end
        end
    end
    
    if bestRule and bestRule.profile then
        self:ScheduleProfileChange(bestRule.profile, bestRule.name)
    end
end

-- Verificar si una condición se cumple
function WCS_BrainAutoProfiles:CheckCondition(condition)
    if condition == "IN_RAID" then
        return GetNumRaidMembers() > 0
    elseif condition == "IN_PARTY" then
        return GetNumPartyMembers() > 0 and GetNumRaidMembers() == 0
    elseif condition == "IN_DUNGEON" then
        local inInstance, instanceType = IsInInstance()
        return inInstance and (instanceType == "party" or instanceType == "raid")
    elseif condition == "IN_BATTLEGROUND" then
        local inInstance, instanceType = IsInInstance()
        return inInstance and instanceType == "pvp"
    elseif condition == "IN_CITY" then
        return self:IsCity(GetZoneText())
    elseif condition == "IN_COMBAT" then
        return UnitAffectingCombat("player")
    elseif condition == "SOLO" then
        return GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0
    elseif condition == "RESTING" then
        return IsResting()
    end
    
    return false
end

-- Programar cambio de perfil
function WCS_BrainAutoProfiles:ScheduleProfileChange(profileName, ruleName)
    -- Verificar que el perfil existe
    if not WCS_BrainProfiles then
        return
    end
    
    -- Verificar que profileName no es nil o vacío
    if not profileName or profileName == "" then
        return
    end
    
    -- Verificar que el perfil existe en la tabla de perfiles
    if not WCS_BrainSaved or not WCS_BrainSaved.profiles or not WCS_BrainSaved.profiles[profileName] then
        return
    end
    
    -- Verificar que no es el perfil actual
    local currentProfile = WCS_BrainProfiles:GetCurrentProfileName()
    if currentProfile == profileName then
        return -- Ya estamos usando este perfil
    end
    
    -- Programar cambio
    pendingProfile = profileName
    pendingTime = 0
    
    if WCS_BrainSaved.autoProfiles.notifications then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFF00FF00[Auto-Perfil]|r Cambiando a |cFFFFFF00%s|r en %d segundos... (Regla: %s)",
            profileName,
            WCS_BrainSaved.autoProfiles.delay,
            ruleName
        ))
    end
end

-- Aplicar perfil pendiente
function WCS_BrainAutoProfiles:ApplyPendingProfile()
    if not pendingProfile then
        return
    end
    
    isChanging = true
    
    -- Cargar perfil
    if WCS_BrainProfiles then
        WCS_BrainProfiles:LoadProfile(pendingProfile)
        
        if WCS_BrainSaved.autoProfiles.notifications then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cFF00FF00[Auto-Perfil]|r Perfil |cFFFFFF00%s|r aplicado",
                pendingProfile
            ))
        end
        
        PlaySound("igMainMenuOptionCheckBoxOn")
    end
    
    -- Limpiar
    pendingProfile = nil
    pendingTime = 0
    
    -- Esperar 1 segundo antes de permitir otro cambio
    local frame = CreateFrame("Frame")
    local elapsed = 0
    frame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= 1 then
            frame:SetScript("OnUpdate", nil)
            isChanging = false
        end
    end)
end

-- Activar sistema
function WCS_BrainAutoProfiles:Enable()
    WCS_BrainSaved.autoProfiles.enabled = true
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Brain]|r Sistema de Perfiles Automáticos |cFF00FF00ACTIVADO|r")
    PlaySound("igMainMenuOptionCheckBoxOn")
    
    -- Evaluar inmediatamente
    self:CheckSituation()
end

-- Desactivar sistema
function WCS_BrainAutoProfiles:Disable()
    WCS_BrainSaved.autoProfiles.enabled = false
    pendingProfile = nil
    pendingTime = 0
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Brain]|r Sistema de Perfiles Automáticos |cFFFF0000DESACTIVADO|r")
    PlaySound("igMainMenuOptionCheckBoxOff")
end

-- Toggle
function WCS_BrainAutoProfiles:Toggle()
    if WCS_BrainSaved.autoProfiles.enabled then
        self:Disable()
    else
        self:Enable()
    end
end

-- Obtener estado
function WCS_BrainAutoProfiles:IsEnabled()
    return WCS_BrainSaved.autoProfiles.enabled
end

-- Obtener configuración
function WCS_BrainAutoProfiles:GetConfig()
    return WCS_BrainSaved.autoProfiles
end

-- Actualizar regla
function WCS_BrainAutoProfiles:UpdateRule(index, profile, enabled)
    if not WCS_BrainSaved.autoProfiles.rules[index] then
        return false
    end
    
    if profile then
        WCS_BrainSaved.autoProfiles.rules[index].profile = profile
    end
    
    if enabled ~= nil then
        WCS_BrainSaved.autoProfiles.rules[index].enabled = enabled
    end
    
    return true
end

-- Obtener situación actual
function WCS_BrainAutoProfiles:GetCurrentSituation()
    return currentSituation
end

-- Obtener perfil pendiente
function WCS_BrainAutoProfiles:GetPendingProfile()
    return pendingProfile
end

-- Cancelar cambio pendiente
function WCS_BrainAutoProfiles:CancelPending()
    if pendingProfile then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Auto-Perfil]|r Cambio cancelado")
        pendingProfile = nil
        pendingTime = 0
    end
end

-- ========================================================================
-- FUNCIONES DE DIAGNÓSTICO Y TESTING
-- ========================================================================

function WCS_BrainAutoProfiles:RunDiagnostics()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00========================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Auto-Perfiles] DIAGNÓSTICO COMPLETO|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00========================================|r")
    
    -- 1. Estado del sistema
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00\n1. ESTADO DEL SISTEMA:|r")
    local enabled = self:IsEnabled()
    DEFAULT_CHAT_FRAME:AddMessage("   Sistema: " .. (enabled and "|cFF00FF00ACTIVADO|r" or "|cFFFF0000DESACTIVADO|r"))
    
    if not WCS_BrainSaved or not WCS_BrainSaved.autoProfiles then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000   ERROR: Configuración no encontrada|r")
        return
    end
    
    local config = WCS_BrainSaved.autoProfiles
    DEFAULT_CHAT_FRAME:AddMessage("   Delay: " .. config.delay .. " segundos")
    DEFAULT_CHAT_FRAME:AddMessage("   Notificaciones: " .. (config.notifications and "|cFF00FF00SÍ|r" or "|cFFFF0000NO|r"))
    DEFAULT_CHAT_FRAME:AddMessage("   Intervalo: " .. config.checkInterval .. " segundos")
    
    -- 2. Situación actual
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00\n2. SITUACIÓN ACTUAL:|r")
    DEFAULT_CHAT_FRAME:AddMessage("   Detectada: |cFF00FFFF" .. currentSituation .. "|r")
    
    local inRaid = GetNumRaidMembers() > 0
    local inParty = GetNumPartyMembers() > 0
    local inInstance, instanceType = IsInInstance()
    local zoneName = GetRealZoneText() or "Desconocida"
    
    DEFAULT_CHAT_FRAME:AddMessage("   En Raid: " .. (inRaid and "|cFF00FF00SÍ|r (" .. GetNumRaidMembers() .. " miembros)" or "|cFFFF0000NO|r"))
    DEFAULT_CHAT_FRAME:AddMessage("   En Party: " .. (inParty and "|cFF00FF00SÍ|r (" .. GetNumPartyMembers() .. " miembros)" or "|cFFFF0000NO|r"))
    DEFAULT_CHAT_FRAME:AddMessage("   En Instancia: " .. (inInstance and "|cFF00FF00SÍ|r" or "|cFFFF0000NO|r"))
    if inInstance then
        DEFAULT_CHAT_FRAME:AddMessage("   Tipo: |cFF00FFFF" .. (instanceType or "unknown") .. "|r")
    end
    DEFAULT_CHAT_FRAME:AddMessage("   Zona: |cFF00FFFF" .. zoneName .. "|r")
    
    -- 3. Reglas configuradas
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00\n3. REGLAS CONFIGURADAS:|r")
    if config.rules then
        for i = 1, table.getn(config.rules) do
            local rule = config.rules[i]
            local status = rule.enabled and "|cFF00FF00✓|r" or "|cFFFF0000✗|r"
            DEFAULT_CHAT_FRAME:AddMessage("   " .. status .. " [P" .. rule.priority .. "] " .. rule.condition .. " → " .. rule.profile)
        end
    end
    
    -- 4. Perfil actual
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00\n4. PERFIL ACTUAL:|r")
    if WCS_BrainProfiles and WCS_BrainProfiles.GetCurrentProfileName then
        local currentProfile = WCS_BrainProfiles.GetCurrentProfileName()
        DEFAULT_CHAT_FRAME:AddMessage("   Activo: |cFF00FFFF" .. currentProfile .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000   ERROR: WCS_BrainProfiles no disponible|r")
    end
    
    -- 5. Cambio pendiente
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00\n5. CAMBIO PENDIENTE:|r")
    if pendingProfile then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00   Programado: " .. pendingProfile .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("   Tiempo restante: ~" .. math.floor(pendingTime) .. "s")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF888888   Ninguno|r")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00========================================|r")
    PlaySound("igMainMenuOptionCheckBoxOn")
end

function WCS_BrainAutoProfiles:ForceCheck()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Auto-Perfil]|r Forzando verificación...")
    
    if not self:IsEnabled() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Sistema desactivado. Usa /ap on|r")
        return
    end
    
    self:CheckAndApply()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Auto-Perfil]|r Verificación completada")
end

-- Comando slash
SLASH_AUTOPROFILE1 = "/autoprofile"
SLASH_AUTOPROFILE2 = "/ap"
SlashCmdList["AUTOPROFILE"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "on" or msg == "enable" then
        WCS_BrainAutoProfiles:Enable()
    elseif msg == "off" or msg == "disable" then
        WCS_BrainAutoProfiles:Disable()
    elseif msg == "toggle" or msg == "" then
        WCS_BrainAutoProfiles:Toggle()
    elseif msg == "status" then
        local status = WCS_BrainAutoProfiles:IsEnabled() and "|cFF00FF00ACTIVADO|r" or "|cFFFF0000DESACTIVADO|r"
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Auto-Perfil]|r Estado: " .. status)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Auto-Perfil]|r Situación actual: " .. currentSituation)
        if pendingProfile then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Auto-Perfil]|r Cambio pendiente: " .. pendingProfile)
        end
    elseif msg == "cancel" then
        WCS_BrainAutoProfiles:CancelPending()
    elseif msg == "test" or msg == "debug" then
        WCS_BrainAutoProfiles:RunDiagnostics()
    elseif msg == "force" then
        WCS_BrainAutoProfiles:ForceCheck()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Auto-Perfil]|r Comandos disponibles:")
        DEFAULT_CHAT_FRAME:AddMessage("  /ap on - Activar")
        DEFAULT_CHAT_FRAME:AddMessage("  /ap off - Desactivar")
        DEFAULT_CHAT_FRAME:AddMessage("  /ap toggle - Alternar")
        DEFAULT_CHAT_FRAME:AddMessage("  /ap status - Ver estado")
        DEFAULT_CHAT_FRAME:AddMessage("  /ap cancel - Cancelar cambio pendiente")
        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFFFF00/ap test|r - Diagnóstico completo")
        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFFFF00/ap force|r - Forzar verificación")
    end
end

-- Inicializar al cargar
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "WCS_Brain" then
        WCS_BrainAutoProfiles:Initialize()
    end
end)


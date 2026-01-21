--[[
    WCS_BrainGuardianAlerts.lua
    Sistema de Notificaciones Visuales para Modo Guardián
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.0.0
    
    Proporciona alertas visuales cuando la mascota protege al aliado:
    - Mensajes en pantalla (UIErrorsFrame)
    - Frame de alerta personalizado
    - Efectos de sonido
    - Iconos de estado
]]--

if not WCS_BrainPetAI then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Guardian Alerts]|r ERROR: WCS_BrainPetAI no encontrado")
    return
end

local PetAI = WCS_BrainPetAI

-- ============================================================================
-- CONFIGURACIÓN DE ALERTAS
-- ============================================================================

PetAI.GuardianAlerts = PetAI.GuardianAlerts or {
    enabled = true,
    showScreenMessages = true,
    showAlertFrame = true,
    playSound = true,
    
    -- Cooldowns para evitar spam
    lastAlertTime = 0,
    alertCooldown = 2,  -- segundos entre alertas
    
    -- Tipos de alertas
    alertTypes = {
        UNDER_ATTACK = { color = "|cFFFF0000", sound = "RaidWarning", icon = "Interface\\Icons\\Ability_Warrior_Challange" },
        DEFENDING = { color = "|cFFFF6600", sound = "TellMessage", icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance" },
        TAUNT_USED = { color = "|cFFFFAA00", sound = "igQuestComplete", icon = "Interface\\Icons\\Spell_Nature_Reincarnation" },
        EMERGENCY = { color = "|cFFFF0000", sound = "RaidWarning", icon = "Interface\\Icons\\Spell_Shadow_SoulGem" },
        PROTECTED = { color = "|cFF00FF00", sound = "LevelUp", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" }
    }
}

local Alerts = PetAI.GuardianAlerts

-- ============================================================================
-- FRAME DE ALERTA PERSONALIZADO
-- ============================================================================

-- Crear frame de alerta
local alertFrame = CreateFrame("Frame", "WCS_GuardianAlertFrame", UIParent)
alertFrame:SetWidth(300)
alertFrame:SetHeight(80)
alertFrame:SetPoint("TOP", UIParent, "TOP", 0, -150)
alertFrame:SetFrameStrata("HIGH")
alertFrame:Hide()

-- Background
local bg = alertFrame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(alertFrame)
bg:SetTexture(0, 0, 0, 0.8)

-- Border
local border = alertFrame:CreateTexture(nil, "BORDER")
border:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
border:SetAllPoints(alertFrame)

-- Icon
local icon = alertFrame:CreateTexture(nil, "ARTWORK")
icon:SetWidth(48)
icon:SetHeight(48)
icon:SetPoint("LEFT", alertFrame, "LEFT", 10, 0)
icon:SetTexture("Interface\\Icons\\Ability_Warrior_DefensiveStance")
alertFrame.icon = icon

-- Title text
local title = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
title:SetPoint("RIGHT", alertFrame, "RIGHT", -10, 0)
title:SetJustifyH("LEFT")
title:SetText("¡MODO GUARDIÁN!")
alertFrame.title = title

-- Message text
local message = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
message:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
message:SetPoint("RIGHT", alertFrame, "RIGHT", -10, 0)
message:SetJustifyH("LEFT")
message:SetText("Protegiendo al aliado...")
alertFrame.message = message

-- Animation: Fade in/out
local fadeIn = 0.3
local fadeOut = 0.3
local displayTime = 3

alertFrame.elapsed = 0
alertFrame.phase = "hidden"  -- hidden, fadein, display, fadeout

alertFrame:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    
    if this.phase == "fadein" then
        local alpha = math.min(this.elapsed / fadeIn, 1)
        this:SetAlpha(alpha)
        if alpha >= 1 then
            this.phase = "display"
            this.elapsed = 0
        end
    elseif this.phase == "display" then
        if this.elapsed >= displayTime then
            this.phase = "fadeout"
            this.elapsed = 0
        end
    elseif this.phase == "fadeout" then
        local alpha = math.max(1 - (this.elapsed / fadeOut), 0)
        this:SetAlpha(alpha)
        if alpha <= 0 then
            this:Hide()
            this.phase = "hidden"
            this.elapsed = 0
        end
    end
end)

-- ============================================================================
-- FUNCIONES DE ALERTA
-- ============================================================================

-- Mostrar alerta en pantalla
function Alerts:ShowAlert(alertType, allyName, details)
    if not self.enabled then return end
    
    -- Verificar cooldown
    local now = GetTime()
    if now - self.lastAlertTime < self.alertCooldown then
        return
    end
    self.lastAlertTime = now
    
    local alertConfig = self.alertTypes[alertType]
    if not alertConfig then return end
    
    -- Mensaje en UIErrorsFrame (centro superior de pantalla)
    if self.showScreenMessages then
        local msg = alertConfig.color .. details .. "|r"
        UIErrorsFrame:AddMessage(msg, 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME)
    end
    
    -- Frame de alerta personalizado
    if self.showAlertFrame then
        alertFrame.icon:SetTexture(alertConfig.icon)
        alertFrame.title:SetText(alertConfig.color .. "MODO GUARDIÁN|r")
        alertFrame.message:SetText(details)
        
        alertFrame.phase = "fadein"
        alertFrame.elapsed = 0
        alertFrame:SetAlpha(0)
        alertFrame:Show()
    end
    
    -- Sonido
    if self.playSound and alertConfig.sound then
        PlaySound(alertConfig.sound)
    end
end

-- Alerta: Aliado bajo ataque
function Alerts:AllyUnderAttack(allyName, attackerName)
    local details = string.format("¡%s está siendo atacado por %s!", allyName or "Aliado", attackerName or "enemigo")
    self:ShowAlert("UNDER_ATTACK", allyName, details)
end

-- Alerta: Defendiendo al aliado
function Alerts:Defending(allyName, attackerName)
    local details = string.format("Defendiendo a %s de %s", allyName or "aliado", attackerName or "enemigo")
    self:ShowAlert("DEFENDING", allyName, details)
end

-- Alerta: Taunt usado
function Alerts:TauntUsed(abilityName, allyName)
    local details = string.format("%s usado! Protegiendo a %s", abilityName or "Taunt", allyName or "aliado")
    self:ShowAlert("TAUNT_USED", allyName, details)
end

-- Alerta: Emergencia
function Alerts:Emergency(allyName, hpPercent)
    local details = string.format("¡EMERGENCIA! %s al %d%% HP", allyName or "Aliado", hpPercent or 0)
    self:ShowAlert("EMERGENCY", allyName, details)
end

-- Alerta: Aliado protegido exitosamente
function Alerts:Protected(allyName)
    local details = string.format("%s está a salvo", allyName or "Aliado")
    self:ShowAlert("PROTECTED", allyName, details)
end

-- ============================================================================
-- INTEGRACIÓN CON GUARDIANENHANCED
-- ============================================================================

-- Hook para GuardianDefend
if PetAI.GuardianDefend then
    local OriginalGuardianDefend = PetAI.GuardianDefend
    
    function PetAI:GuardianDefend(guardianUnit)
        local result = OriginalGuardianDefend(self, guardianUnit)
        
        if result and self.GuardianTarget then
            local guardianHP = self:GetUnitHealthPercent(guardianUnit)
            
            -- Alerta de emergencia si HP crítico
            if guardianHP < 30 then
                Alerts:Emergency(self.GuardianTarget, math.floor(guardianHP))
            -- Alerta de defensa normal
            elseif self.Guardian.isUnderAttack then
                -- Intentar obtener nombre del atacante
                local attackerName = "enemigo"
                if UnitExists("pettarget") then
                    attackerName = UnitName("pettarget") or "enemigo"
                end
                Alerts:Defending(self.GuardianTarget, attackerName)
            end
        end
        
        return result
    end
end

-- Hook para habilidades de taunt
local function HookTauntAbility(abilityName)
    -- Este hook se activará cuando se use una habilidad de taunt
    if PetAI.GuardianTarget and PetAI.currentMode == 4 then
        Alerts:TauntUsed(abilityName, PetAI.GuardianTarget)
    end
end

-- Registrar hooks para habilidades específicas
if PetAI.ExecuteAbility then
    local OriginalExecuteAbility = PetAI.ExecuteAbility
    
    function PetAI:ExecuteAbility(abilityName)
        local result = OriginalExecuteAbility(self, abilityName)
        
        if result and self.currentMode == 4 and self.GuardianTarget then
            -- Detectar habilidades de taunt/defensa
            local tauntAbilities = {
                ["Torment"] = true,
                ["Suffering"] = true,
                ["Anguish"] = true,
                ["Seduction"] = true,
                ["Spell Lock"] = true
            }
            
            if tauntAbilities[abilityName] then
                HookTauntAbility(abilityName)
            end
        end
        
        return result
    end
end

-- ============================================================================
-- COMANDOS
-- ============================================================================

SLASH_GUARDIANALERTS1 = "/guardianalerts"
SLASH_GUARDIANALERTS2 = "/galerts"
SlashCmdList["GUARDIANALERTS"] = function(msg)
    local cmd = string.lower(msg or "")
    
    if cmd == "on" then
        Alerts.enabled = true
        PetAI:Print("Alertas de Guardián: |cFF00FF00ACTIVADAS|r")
    elseif cmd == "off" then
        Alerts.enabled = false
        PetAI:Print("Alertas de Guardián: |cFFFF0000DESACTIVADAS|r")
    elseif cmd == "screen" then
        Alerts.showScreenMessages = not Alerts.showScreenMessages
        PetAI:Print("Mensajes en pantalla: " .. (Alerts.showScreenMessages and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
    elseif cmd == "frame" then
        Alerts.showAlertFrame = not Alerts.showAlertFrame
        PetAI:Print("Frame de alerta: " .. (Alerts.showAlertFrame and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
    elseif cmd == "sound" then
        Alerts.playSound = not Alerts.playSound
        PetAI:Print("Sonidos: " .. (Alerts.playSound and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
    elseif cmd == "test" then
        -- Probar alerta
        Alerts:Defending("TestAlly", "TestEnemy")
        PetAI:Print("Alerta de prueba enviada")
    elseif cmd == "status" then
        PetAI:Print("=== Estado de Alertas de Guardián ===")
        PetAI:Print("  Activadas: " .. (Alerts.enabled and "|cFF00FF00SI|r" or "|cFFFF0000NO|r"))
        PetAI:Print("  Mensajes en pantalla: " .. (Alerts.showScreenMessages and "|cFF00FF00SI|r" or "|cFFFF0000NO|r"))
        PetAI:Print("  Frame de alerta: " .. (Alerts.showAlertFrame and "|cFF00FF00SI|r" or "|cFFFF0000NO|r"))
        PetAI:Print("  Sonidos: " .. (Alerts.playSound and "|cFF00FF00SI|r" or "|cFFFF0000NO|r"))
    else
        PetAI:Print("=== Comandos de Alertas de Guardián ===")
        PetAI:Print("  /galerts on/off - Activar/desactivar alertas")
        PetAI:Print("  /galerts screen - Toggle mensajes en pantalla")
        PetAI:Print("  /galerts frame - Toggle frame de alerta")
        PetAI:Print("  /galerts sound - Toggle sonidos")
        PetAI:Print("  /galerts test - Probar alerta")
        PetAI:Print("  /galerts status - Ver estado")
    end
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFAA[Guardian Alerts]|r Sistema de notificaciones visuales cargado v1.0.0")
DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFAA[Guardian Alerts]|r Usa /galerts para configurar")

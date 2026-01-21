--[[
WCS_BrainMajorDemonAlerts.lua v1.0.0
Sistema de Alertas Visuales para Demonios Mayores

Compatible con Lua 5.0 (Turtle WoW / WoW 1.12)

Proporciona alertas visuales y sonoras cuando un demonio mayor está por expirar.
]]

WCS_BrainMajorDemonAlerts = WCS_BrainMajorDemonAlerts or {}
local MDA = WCS_BrainMajorDemonAlerts

MDA.VERSION = "1.0.0"
MDA.enabled = true

-- ============================================================================
-- FRAME DE ALERTA VISUAL
-- ============================================================================

-- Crear frame principal
MDA.alertFrame = CreateFrame("Frame", "WCS_MajorDemonAlertFrame", UIParent)
MDA.alertFrame:SetWidth(400)
MDA.alertFrame:SetHeight(80)
MDA.alertFrame:SetPoint("TOP", UIParent, "TOP", 0, -150)
MDA.alertFrame:SetFrameStrata("HIGH")
MDA.alertFrame:Hide()

-- Background
MDA.alertFrame.bg = MDA.alertFrame:CreateTexture(nil, "BACKGROUND")
MDA.alertFrame.bg:SetAllPoints(MDA.alertFrame)
MDA.alertFrame.bg:SetTexture(0, 0, 0, 0.8)

-- Border
MDA.alertFrame.border = MDA.alertFrame:CreateTexture(nil, "BORDER")
MDA.alertFrame.border:SetAllPoints(MDA.alertFrame)
MDA.alertFrame.border:SetTexture(1, 0, 0, 1)

-- Texto principal
MDA.alertFrame.text = MDA.alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
MDA.alertFrame.text:SetPoint("CENTER", MDA.alertFrame, "CENTER", 0, 10)
MDA.alertFrame.text:SetTextColor(1, 1, 0, 1)

-- Texto de tiempo
MDA.alertFrame.timeText = MDA.alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
MDA.alertFrame.timeText:SetPoint("CENTER", MDA.alertFrame, "CENTER", 0, -15)
MDA.alertFrame.timeText:SetTextColor(1, 0, 0, 1)

-- Variables de animación
MDA.alertFrame.fadeTime = 0
MDA.alertFrame.displayTime = 0
MDA.alertFrame.isShowing = false

-- ============================================================================
-- FUNCIONES DE ALERTA
-- ============================================================================

function MDA:ShowAlert(demonType, timeRemaining, urgency)
    if not self.enabled then
        return
    end
    
    -- Determinar color según urgencia
    local r, g, b = 1, 1, 0  -- Amarillo por defecto
    local soundFile = "RaidWarning"
    
    if urgency == "critical" then
        r, g, b = 1, 0, 0  -- Rojo
        soundFile = "AlarmClockWarning3"
    elseif urgency == "high" then
        r, g, b = 1, 0.5, 0  -- Naranja
        soundFile = "RaidWarning"
    end
    
    -- Configurar textos
    local demonName = demonType
    if demonType == "Infernal" then
        demonName = "INFERNAL"
    elseif demonType == "Doomguard" then
        demonName = "DOOMGUARD"
    end
    
    self.alertFrame.text:SetText("¡" .. demonName .. " EXPIRANDO!")
    self.alertFrame.text:SetTextColor(r, g, b, 1)
    
    self.alertFrame.timeText:SetText(string.format("%d SEGUNDOS", timeRemaining))
    self.alertFrame.timeText:SetTextColor(r, g, b, 1)
    
    self.alertFrame.border:SetTexture(r, g, b, 1)
    
    -- Mostrar frame
    self.alertFrame:Show()
    self.alertFrame:SetAlpha(1)
    self.alertFrame.fadeTime = 0
    self.alertFrame.displayTime = 5  -- Mostrar por 5 segundos
    self.alertFrame.isShowing = true
    
    -- Sonido
    PlaySound(soundFile)
    
    -- Mensaje en UIErrorsFrame (centro de la pantalla)
    UIErrorsFrame:AddMessage("¡" .. demonName .. " EXPIRA EN " .. timeRemaining .. "s!", r, g, b, 1.0, UIERRORS_HOLD_TIME)
    
    -- Mensaje en chat
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000[ALERTA DEMONIO]|r %s expira en %d segundos!", demonName, timeRemaining))
end

function MDA:HideAlert()
    self.alertFrame:Hide()
    self.alertFrame.isShowing = false
end

-- ============================================================================
-- UPDATE DEL FRAME
-- ============================================================================

MDA.alertFrame:SetScript("OnUpdate", function()
    if not this.isShowing then
        return
    end
    
    this.displayTime = this.displayTime - arg1
    
    if this.displayTime <= 0 then
        -- Fade out
        this.fadeTime = this.fadeTime + arg1
        local alpha = 1 - (this.fadeTime / 1.0)
        if alpha < 0 then
            alpha = 0
            MDA:HideAlert()
        end
        this:SetAlpha(alpha)
    else
        -- Efecto de parpadeo para alertas críticas
        if this.displayTime > 0 then
            local pulse = math.abs(math.sin(GetTime() * 3))
            this:SetAlpha(0.7 + (pulse * 0.3))
        end
    end
end)

-- ============================================================================
-- COMANDOS
-- ============================================================================

SLASH_MDALERTS1 = "/mdalerts"
SlashCmdList["MDALERTS"] = function(msg)
    if not msg then
        msg = ""
    end
    local cmd = string.lower(msg)
    
    if cmd == "on" then
        MDA.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[MajorDemonAlerts]|r Alertas activadas")
    elseif cmd == "off" then
        MDA.enabled = false
        MDA:HideAlert()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[MajorDemonAlerts]|r Alertas desactivadas")
    elseif cmd == "test" then
        MDA:ShowAlert("Infernal", 15, "critical")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[MajorDemonAlerts]|r Mostrando alerta de prueba")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[MajorDemonAlerts]|r Comandos:")
        DEFAULT_CHAT_FRAME:AddMessage("  /mdalerts on - Activar alertas")
        DEFAULT_CHAT_FRAME:AddMessage("  /mdalerts off - Desactivar alertas")
        DEFAULT_CHAT_FRAME:AddMessage("  /mdalerts test - Probar alerta")
    end
end

-- ============================================================================
-- INICIALIZACION
-- ============================================================================

DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[MajorDemonAlerts]|r v" .. MDA.VERSION .. " cargado")

--[[
    WCS_BrainAutoExecute.lua - Sistema de Ejecución Automática
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.0.0
    
    Este módulo ejecuta automáticamente las decisiones de WCS_Brain
    cuando está en combate, sin necesidad de WCS_DQN.
]]--

WCS_BrainAutoExecute = WCS_BrainAutoExecute or {}
WCS_BrainAutoExecute.VERSION = "1.0.0"
WCS_BrainAutoExecute.enabled = false

-- ============================================================================
-- UTILIDADES
-- ============================================================================
local function getTime()
    return GetTime and GetTime() or 0
end

local function debugPrint(msg)
    if WCS_Brain and WCS_Brain.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFF[AutoExecute]|r " .. tostring(msg))
    end
end

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================
WCS_BrainAutoExecute.Config = {
    -- Intervalo mínimo entre decisiones (segundos)
    decisionInterval = 0.2,
    
    -- Solo ejecutar en combate
    combatOnly = true,
    
    -- Respetar GCD
    respectGCD = true
}

-- ============================================================================
-- ESTADO
-- ============================================================================
WCS_BrainAutoExecute.State = {
    lastDecisionTime = 0,
    lastExecutionTime = 0,
    inCombat = false
}

-- ============================================================================
-- FRAME DE ACTUALIZACIÓN
-- ============================================================================
function WCS_BrainAutoExecute:CreateUpdateFrame()
    if self.updateFrame then return end
    
    self.updateFrame = CreateFrame("Frame", "WCS_BrainAutoExecuteFrame")
    self.updateFrame.elapsed = 0
    
    self.updateFrame:SetScript("OnUpdate", function()
        this.elapsed = this.elapsed + arg1
        
        -- Actualizar cada 0.1 segundos
        if this.elapsed >= 0.1 then
            this.elapsed = 0
            WCS_BrainAutoExecute:OnUpdate()
        end
    end)
    
    debugPrint("Frame de actualización creado")
end

function WCS_BrainAutoExecute:OnUpdate()
    if not self.enabled then return end
    if not WCS_Brain or not WCS_Brain.ENABLED then return end
    
    -- Actualizar estado de combate
    local inCombat = UnitAffectingCombat("player")
    self.State.inCombat = inCombat
    
    -- Solo ejecutar en combate si está configurado
    if self.Config.combatOnly and not inCombat then
        return
    end
    
    -- Verificar si tenemos un target hostil
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        return
    end
    
    -- Verificar intervalo mínimo entre decisiones
    local now = getTime()
    local timeSinceLastDecision = now - self.State.lastDecisionTime
    if timeSinceLastDecision < self.Config.decisionInterval then
        return
    end
    
    -- Verificar si estamos casteando
    if WCS_BrainCore and WCS_BrainCore:IsCasting() then
        return
    end
    
    -- Verificar GCD si está configurado
    if self.Config.respectGCD and WCS_BrainCore and WCS_BrainCore:IsOnGCD() then
        return
    end
    
    -- Ejecutar la próxima acción
    self.State.lastDecisionTime = now
    
    local success = false
    if WCS_Brain.Execute then
        -- Usar pcall para evitar errores que rompan el loop
        local ok, result = pcall(function()
            return WCS_Brain:Execute()
        end)
        
        if ok then
            success = result
            if success then
                self.State.lastExecutionTime = now
                debugPrint("Acción ejecutada exitosamente")
            end
        else
            debugPrint("Error al ejecutar: " .. tostring(result))
        end
    end
end

-- ============================================================================
-- EVENTOS
-- ============================================================================
function WCS_BrainAutoExecute:RegisterEvents()
    if self.eventFrame then return end
    
    self.eventFrame = CreateFrame("Frame", "WCS_BrainAutoExecuteEventFrame")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entrar en combate
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Salir de combate
    
    self.eventFrame:SetScript("OnEvent", function()
        if event == "PLAYER_REGEN_DISABLED" then
            WCS_BrainAutoExecute.State.inCombat = true
            debugPrint("Entrando en combate - AutoExecute activo")
        elseif event == "PLAYER_REGEN_ENABLED" then
            WCS_BrainAutoExecute.State.inCombat = false
            debugPrint("Saliendo de combate - AutoExecute en pausa")
        end
    end)
    
    debugPrint("Eventos registrados")
end

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================
function WCS_BrainAutoExecute:Initialize()
    -- Verificar dependencias
    if not WCS_Brain then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[AutoExecute]|r ERROR: WCS_Brain no encontrado")
        self.enabled = false
        return
    end
    
    if not WCS_BrainCore then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[AutoExecute]|r ERROR: WCS_BrainCore no encontrado")
        self.enabled = false
        return
    end
    
    -- Crear frame de actualización
    self:CreateUpdateFrame()
    
    -- Registrar eventos
    self:RegisterEvents()
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS_BrainAutoExecute]|r v" .. self.VERSION .. " - Sistema de ejecución automática cargado")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFF[AutoExecute]|r WCS_Brain ahora ejecutará acciones automáticamente en combate")
end

-- ============================================================================
-- COMANDOS SLASH
-- ============================================================================
SLASH_WCSAUTOEXEC1 = "/autoexec"
SLASH_WCSAUTOEXEC2 = "/brainauto"
SlashCmdList["WCSAUTOEXEC"] = function(msg)
    local cmd = string.lower(msg or "")
    
    if cmd == "on" then
        WCS_BrainAutoExecute.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AutoExecute]|r ACTIVADO")
    elseif cmd == "off" then
        WCS_BrainAutoExecute.enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[AutoExecute]|r DESACTIVADO")
    elseif cmd == "status" then
        local status = WCS_BrainAutoExecute.enabled and "ACTIVO" or "INACTIVO"
        local combat = WCS_BrainAutoExecute.State.inCombat and "SÍ" or "NO"
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFF[AutoExecute]|r Estado: " .. status)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFF[AutoExecute]|r En combate: " .. combat)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFF[AutoExecute]|r Intervalo: " .. WCS_BrainAutoExecute.Config.decisionInterval .. "s")
    elseif cmd == "interval" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFF[AutoExecute]|r Uso: /autoexec interval <segundos>")
    else
        local args = {}
        for word in string.gfind(msg, "%S+") do
            table.insert(args, word)
        end
        
        if args[1] == "interval" and args[2] then
            local interval = tonumber(args[2])
            if interval and interval >= 0.1 and interval <= 2.0 then
                WCS_BrainAutoExecute.Config.decisionInterval = interval
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFF[AutoExecute]|r Intervalo cambiado a: " .. interval .. "s")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[AutoExecute]|r Intervalo inválido (debe ser entre 0.1 y 2.0)")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFF[AutoExecute]|r Comandos:")
            DEFAULT_CHAT_FRAME:AddMessage("  /autoexec on|off - Activar/desactivar")
            DEFAULT_CHAT_FRAME:AddMessage("  /autoexec status - Ver estado")
            DEFAULT_CHAT_FRAME:AddMessage("  /autoexec interval <segundos> - Cambiar intervalo (0.1-2.0)")
        end
    end
end

-- ============================================================================
-- AUTO-INICIALIZACIÓN
-- ============================================================================
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
                WCS_BrainAutoExecute:Initialize()
                delayFrame:SetScript("OnUpdate", nil)
            end
        end)
    end
end)

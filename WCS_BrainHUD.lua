--[[
    WCS_BrainHUD.lua - Interfaz Holográfica "Iron Man" (v7.0)
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Proporciona información visual inmediata cerca del personaje sobre
    el estado de la IA, recursos (shards) y decisiones.
]]--

WCS_BrainHUD = WCS_BrainHUD or {}
WCS_BrainHUD.VERSION = "1.0.0"

-- Configuración visual
WCS_BrainHUD.Config = {
    scale = 0.8,
    alpha = 0.6,
    xOffset = 0,
    yOffset = -150, -- Debajo del personaje por defecto
    enabled = true
}

-- ============================================================================
-- CREACIÓN DE FRAMES
-- ============================================================================

function WCS_BrainHUD:CreateHUD()
    if self.Frame then return end
    
    -- Frame Padre
    self.Frame = CreateFrame("Frame", "WCS_HUD_Main", UIParent)
    self.Frame:SetWidth(256)
    self.Frame:SetHeight(128)
    self.Frame:SetPoint("CENTER", "UIParent", "CENTER", self.Config.xOffset, self.Config.yOffset)
    self.Frame:SetScale(self.Config.scale)
    self.Frame:SetAlpha(self.Config.alpha)
    
    -- Icono Central (Decisión de IA)
    self.IconFrame = CreateFrame("Frame", "WCS_HUD_Icon", self.Frame)
    self.IconFrame:SetWidth(48)
    self.IconFrame:SetHeight(48)
    self.IconFrame:SetPoint("CENTER", self.Frame, "CENTER", 0, 10)
    
    self.IconTexture = self.IconFrame:CreateTexture(nil, "ARTWORK")
    self.IconTexture:SetAllPoints(self.IconFrame)
    self.IconTexture:SetTexture("Interface\\Icons\\Inv_Misc_QuestionMark")
    
    -- Borde del Icono
    self.IconBorder = self.IconFrame:CreateTexture(nil, "OVERLAY")
    self.IconBorder:SetWidth(80)
    self.IconBorder:SetHeight(80)
    self.IconBorder:SetPoint("CENTER", self.IconFrame, "CENTER", 0, 0)
    self.IconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    self.IconBorder:SetVertexColor(0.5, 0.8, 1, 0.8) -- Azul holográfico
    self.IconBorder:SetBlendMode("ADD")
    
    -- Anillo de Shards (Izquierda)
    self.ShardsFrame = CreateFrame("Frame", "WCS_HUD_Shards", self.Frame)
    self.ShardsFrame:SetWidth(32)
    self.ShardsFrame:SetHeight(32)
    self.ShardsFrame:SetPoint("RIGHT", self.IconFrame, "LEFT", -20, 0)
    
    self.ShardIcon = self.ShardsFrame:CreateTexture(nil, "ARTWORK")
    self.ShardIcon:SetAllPoints()
    self.ShardIcon:SetTexture("Interface\\Icons\\Inv_Misc_Gem_Amethyst_02")
    
    self.ShardCount = self.ShardsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    self.ShardCount:SetPoint("CENTER", self.ShardsFrame, "CENTER", 0, 0)
    self.ShardCount:SetTextColor(1, 0.5, 1, 1) -- Purpura
    self.ShardCount:SetText("0")
    
    -- Texto de Acción (Debajo del icono)
    self.ActionText = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.ActionText:SetPoint("TOP", self.IconFrame, "BOTTOM", 0, -5)
    self.ActionText:SetTextColor(0.8, 0.9, 1, 1)
    self.ActionText:SetText("Esperando...")
    
    -- Eventos para actualizar
    if WCS_EventManager then
        -- Usar OnUpdate throttling para animación suave pero eficiente
        self.Frame:SetScript("OnUpdate", function() WCS_BrainHUD:OnUpdate(arg1) end)
    end
end

-- ============================================================================
-- LÓGICA DE ACTUALIZACIÓN
-- ============================================================================

local updateTimer = 0
function WCS_BrainHUD:OnUpdate(elapsed)
    updateTimer = updateTimer + (elapsed or 0)
    if updateTimer < 0.1 then return end -- 10 FPS es suficiente para HUD informativo
    updateTimer = 0
    
    if not self.Config.enabled then 
        if self.Frame:IsVisible() then self.Frame:Hide() end
        return 
    end
    
    -- 1. Actualizar Shards
    if WCS_ResourceManager then
        local shards = WCS_ResourceManager:GetShardCount()
        self.ShardCount:SetText(tostring(shards))
        if shards < 3 then
            self.ShardCount:SetTextColor(1, 0.2, 0.2, 1) -- Rojo si bajo
        else
            self.ShardCount:SetTextColor(1, 0.5, 1, 1) -- Purpura normal
        end
    end
    
    -- 2. Actualizar Decisión de IA
    -- Leer la última acción decidida por Brain
    if WCS_Brain and WCS_Brain.CurrentDecision then
        local action = WCS_Brain.CurrentDecision
        if action and action.spell then
            -- Buscar textura
            local icon = self:GetSpellTexture(action.spell)
            self.IconTexture:SetTexture(icon or "Interface\\Icons\\Inv_Misc_QuestionMark")
            self.ActionText:SetText(action.spell)
            
            -- Colorear borde según prioridad
            if action.priority == 1 then -- Emergency
                self.IconBorder:SetVertexColor(1, 0, 0, 1)
            elseif action.priority == 9 then -- Filler
                self.IconBorder:SetVertexColor(0.5, 0.8, 1, 0.5)
            else
                self.IconBorder:SetVertexColor(1, 0.8, 0, 0.8)
            end
        else
            self.IconTexture:SetTexture("Interface\\Icons\\Inv_Misc_QuestionMark")
            self.ActionText:SetText("Idle")
            self.IconBorder:SetVertexColor(0.5, 0.5, 0.5, 0.5)
        end
    end
    
    -- Ocultar si no hay target ni combate
    if not UnitExists("target") and not UnitAffectingCombat("player") then
        if self.Frame:GetAlpha() > 0 then
            self.Frame:SetAlpha(self.Frame:GetAlpha() - 0.1)
        end
    else
        if self.Frame:GetAlpha() < self.Config.alpha then
            self.Frame:SetAlpha(self.Frame:GetAlpha() + 0.1)
        end
    end
end

-- Helper para obtener icono
function WCS_BrainHUD:GetSpellTexture(spellName)
    if not spellName then return nil end
    -- Intentar obtener del SpellDB si existe
    if WCS_SpellDB and WCS_SpellDB.GetSpellTexture then
        return WCS_SpellDB:GetSpellTexture(spellName)
    end
    -- Fallback: GetSpellTexture necesita ID, no nombre en 1.12 standard
    -- pero podemos usar WCS_BrainCore:FindSpellSlot
    if WCS_BrainCore then
        local slot = WCS_BrainCore:FindSpellSlot(spellName)
        if slot then
            return GetSpellTexture(slot, BOOKTYPE_SPELL)
        end
    end
    return nil
end

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================

function WCS_BrainHUD:Initialize()
    self:CreateHUD()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS_BrainHUD]|r Interfaz Holografica cargado. /brainhud toggle")
end

-- Evento de carga
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() WCS_BrainHUD:Initialize() end)

-- Comando Slash
SLASH_WCSBRAINHUD1 = "/brainhud"
SlashCmdList["WCSBRAINHUD"] = function(msg)
    WCS_BrainHUD.Config.enabled = not WCS_BrainHUD.Config.enabled
    DEFAULT_CHAT_FRAME:AddMessage("WCS_BrainHUD: " .. (WCS_BrainHUD.Config.enabled and "ON" or "OFF"))
end

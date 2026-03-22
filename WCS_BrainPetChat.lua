--[[
    WCS_BrainPetChat.lua - Sistema de Chat de Mascotas v8.0.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Las mascotas "hablan" según su personalidad
    
    Autor: Elnazzareno (DarckRovert)
]]--

WCS_BrainPetChat = WCS_BrainPetChat or {}
WCS_BrainPetChat.VERSION = "8.0.0"
WCS_BrainPetChat.enabled = true
WCS_BrainPetChat.currentPet = nil

-- ============================================================================
-- DIÁLOGOS POR MASCOTA
-- ============================================================================
WCS_BrainPetChat.Dialogs = {
    ["Imp"] = {
        onSummon = {"¡Jijiji! ¿Qué vamos a quemar hoy?", "¡Aquí estoy! ¿Necesitas fuego?", "¡Yay! ¡Hora de jugar!"},
        onCombat = {"¡Déjame lanzar bolas de fuego!", "¡Quema, quema!", "¡Esto será divertido!"},
        onLowMana = {"Oye, ¿no deberías usar Life Tap?", "Tu mana está bajo...", "¡Necesitas más poder!"},
        onVictory = {"¡Eso fue divertido! ¿Otro?", "¡Jijiji! ¡Ganamos!", "¿Ya? Quiero más..."},
        onDeath = {"¡Auch! Eso dolió...", "¡Noooo!", "*desaparece en humo*"},
        onDismiss = {"¿Ya me vas? Bueno...", "¡Hasta luego!", "*suspiro* Adiós..."}
    },
    
    ["Voidwalker"] = {
        onSummon = {"Estoy aquí para protegerte.", "A tus órdenes.", "Listo para servir."},
        onCombat = {"Déjame tanquear esto.", "Yo me encargo.", "Protegeré al amo."},
        onLowHealth = {"¡Necesito curación!", "Mi salud es baja...", "¡Ayuda!"},
        onTaunt = {"¡Ven aquí, cobarde!", "¡Atácame a mí!", "¡Mírame!"},
        onVictory = {"Amenaza neutralizada.", "Trabajo completado.", "Siguiente objetivo."},
        onDeath = {"He... fallado...", "*gruñido final*", "Perdón, amo..."},
        onDismiss = {"Hasta la próxima.", "Descansaré.", "Adiós, amo."}
    },
    
    ["Succubus"] = {
        onSummon = {"¿Me extrañaste? 😘", "Aquí estoy, cariño~", "¿Necesitas... ayuda?"},
        onCombat = {"Déjame encantar a ese...", "Esto será fácil~", "¡Mío!"},
        onSeduce = {"Ven aquí, guapo~", "No puedes resistirte...", "*guiño*"},
        onVictory = {"Demasiado fácil.", "¿Eso es todo?", "Ni siquiera sudé~"},
        onDeath = {"¡Imposible!", "¿Cómo te atreves?", "*grito*"},
        onDismiss = {"¿Ya te vas? Qué aburrido...", "Hasta pronto, amor~", "Te extrañaré..."}
    },
    
    ["Felhunter"] = {
        onSummon = {"*Gruñido* Listo para cazar.", "Huelo magia...", "*olfatea*"},
        onCombat = {"Detecto magia...", "*gruñido agresivo*", "¡Presa!"},
        onDevour = {"*Nom nom* ¡Delicioso!", "*mastica magia*", "Más..."},
        onSpellLock = {"¡Silencio!", "*interrumpe*", "¡No!"},
        onVictory = {"*Gruñido satisfecho*", "Caza exitosa.", "*mueve cola*"},
        onDeath = {"*aullido*", "*whimper*", "..."},
        onDismiss = {"*gruñido triste*", "Adiós...", "*se va arrastrando*"}
    }
}

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================
function WCS_BrainPetChat:Initialize()
    self:RegisterEvents()
    self:DetectCurrentPet()
    
    if WCS_BrainLogger then
        WCS_BrainLogger:Info("PetChat", "Sistema de chat de mascotas inicializado")
    end
end

-- ============================================================================
-- EVENTOS
-- ============================================================================
function WCS_BrainPetChat:RegisterEvents()
    if not self.frame then
        self.frame = CreateFrame("Frame")
    end
    
    self.frame:RegisterEvent("UNIT_PET")
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
    
    local function OnEvent()
        if event == "UNIT_PET" and arg1 == "player" then
            WCS_BrainPetChat:OnPetChanged()
        elseif event == "PLAYER_REGEN_DISABLED" then
            WCS_BrainPetChat:OnEnterCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            WCS_BrainPetChat:OnLeaveCombat()
        elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
            WCS_BrainPetChat:OnMobDeath(arg1)
        end
    end
    
    self.frame:SetScript("OnEvent", OnEvent)
end

-- ============================================================================
-- DETECCIÓN DE MASCOTA
-- ============================================================================
function WCS_BrainPetChat:DetectCurrentPet()
    if not UnitExists("pet") then
        self.currentPet = nil
        return
    end
    
    -- Usar UnitCreatureFamily para detectar el tipo correcto
    local petFamily = UnitCreatureFamily("pet")
    
    if petFamily then
        -- Mapear familia a tipo de demonio
        if string.find(petFamily, "Imp") then
            self.currentPet = "Imp"
        elseif string.find(petFamily, "Voidwalker") then
            self.currentPet = "Voidwalker"
        elseif string.find(petFamily, "Succubus") then
            self.currentPet = "Succubus"
        elseif string.find(petFamily, "Felhunter") then
            self.currentPet = "Felhunter"
        else
            self.currentPet = petFamily  -- Usar el nombre de la familia directamente
        end
    else
        self.currentPet = nil
    end
end

function WCS_BrainPetChat:OnPetChanged()
    local oldPet = self.currentPet
    self:DetectCurrentPet()
    
    if oldPet and not self.currentPet then
        -- Mascota despedida
        self:Say(oldPet, "onDismiss")
    elseif self.currentPet and self.currentPet ~= oldPet then
        -- Nueva mascota invocada
        self:Say(self.currentPet, "onSummon")
    end
end

-- ============================================================================
-- EVENTOS DE COMBATE
-- ============================================================================
function WCS_BrainPetChat:OnEnterCombat()
    if not self.enabled or not self.currentPet then return end
    self:Say(self.currentPet, "onCombat")
end

function WCS_BrainPetChat:OnLeaveCombat()
    -- Verificar si ganamos
    if not self.enabled or not self.currentPet then return end
    -- Solo decir victoria si la mascota sigue viva
    if UnitExists("pet") and not UnitIsDead("pet") then
        self:Say(self.currentPet, "onVictory")
    end
end

function WCS_BrainPetChat:OnMobDeath(message)
    -- La mascota celebra la victoria
    if not self.enabled or not self.currentPet then return end
    if UnitExists("pet") and not UnitIsDead("pet") then
        self:Say(self.currentPet, "onVictory")
    end
end

-- ============================================================================
-- SISTEMA DE HABLA
-- ============================================================================
function WCS_BrainPetChat:Say(petType, situation)
    if not self.enabled then return end
    if not petType or not self.Dialogs[petType] then return end
    
    local dialogs = self.Dialogs[petType][situation]
    if not dialogs or table.getn(dialogs) == 0 then return end
    
    -- Seleccionar diálogo aleatorio
    local index = math.random(1, table.getn(dialogs))
    local dialog = dialogs[index]
    
    -- Mostrar en chat
    local color = self:GetPetColor(petType)
    DEFAULT_CHAT_FRAME:AddMessage(color .. "[" .. petType .. "]|r " .. dialog)
end

function WCS_BrainPetChat:GetPetColor(petType)
    if petType == "Imp" then
        return "|cFFFF6600"  -- Naranja
    elseif petType == "Voidwalker" then
        return "|cFF9900FF"  -- Púrpura
    elseif petType == "Succubus" then
        return "|cFFFF00FF"  -- Rosa
    elseif petType == "Felhunter" then
        return "|cFF00FF00"  -- Verde
    else
        return "|cFFFFFFFF"  -- Blanco
    end
end

-- ============================================================================
-- COMANDOS SLASH
-- ============================================================================
SLASH_WCSPETCHAT1 = "/wcspetchat"
SLASH_WCSPETCHAT2 = "/brainpetchat"

SlashCmdList["WCSPETCHAT"] = function(msg)
    if msg == "on" then
        WCS_BrainPetChat.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS PetChat]|r Chat de mascotas activado")
        
    elseif msg == "off" then
        WCS_BrainPetChat.enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS PetChat]|r Chat de mascotas desactivado")
        
    elseif msg == "test" then
        -- Detectar mascota actual antes de testear
        WCS_BrainPetChat:DetectCurrentPet()
        if WCS_BrainPetChat.currentPet then
            WCS_BrainPetChat:Say(WCS_BrainPetChat.currentPet, "onSummon")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS PetChat]|r No hay mascota activa")
        end
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS PetChat]|r Comandos:")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFCC00/brainpetchat on|r - Activar chat")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFCC00/brainpetchat off|r - Desactivar chat")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFCC00/brainpetchat test|r - Probar chat")
    end
end

-- Auto-inicialización
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "WCS_Brain" then
        WCS_BrainPetChat:Initialize()
    end
end)

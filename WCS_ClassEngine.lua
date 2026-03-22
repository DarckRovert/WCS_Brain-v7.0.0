--[[
    WCS_ClassEngine.lua — Class Detection & Routing Engine v1.0.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Detecta automaticamente la clase y raza del jugador al login.
    Expone WCS.ClassEngine con metodos para obtener el filler,
    rotacion, cooldowns defensivos y triggers de proc de cada clase.
    
    Funcionalidad REAL — Sin ficcion.
]]--

WCS = WCS or {}
WCS.ClassEngine = WCS.ClassEngine or {}
local CE = WCS.ClassEngine

CE.VERSION = "1.0.0"
CE.class   = nil  -- e.g. "WARLOCK", "WARRIOR", "MAGE", etc.
CE.race    = nil  -- e.g. "Undead", "Orc", "Human", etc.
CE.locale  = GetLocale and GetLocale() or "enUS"

-- ============================================================================
-- DETECTION
-- ============================================================================

function CE:Detect()
    -- UnitClass returns: localizedClass, englishClass in WoW 1.12
    -- Use multi-return assignment (Lua 5.0 compatible, NOT select(2,...))
    local _locClass, englishClass = UnitClass("player")
    local _locRace,  englishRace  = UnitRace("player")
    
    self.class = englishClass or "WARLOCK"
    self.race  = englishRace  or "Undead"
    
    if WCS_BrainLogger then
        WCS_BrainLogger:Log("INFO", "ClassEngine", "Clase detectada: " .. self.class .. " | Raza: " .. self.race)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS ClassEngine]|r Clase: " .. self.class .. " | Raza: " .. self.race)
    end
    
    -- Allow manual override from SavedVars (for testing or edge cases)
    if WCS_BrainSaved and WCS_BrainSaved.Config and WCS_BrainSaved.Config.ClassOverride then
        self.class = WCS_BrainSaved.Config.ClassOverride
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[WCS ClassEngine]|r Override activo: " .. self.class)
    end
    
    -- Propagate to ClassRotations
    if WCS.ClassRotations then
        WCS.ClassRotations:SetClass(self.class)
    end
end

-- ============================================================================
-- ACCESSORS
-- ============================================================================

-- Returns the primary filler spell for the detected class
function CE:GetFiller()
    if not WCS.ClassRotations then return "Auto Attack" end
    local rot = WCS.ClassRotations:GetData()
    return rot and rot.filler or "Auto Attack"
end

-- Returns the full ordered rotation table for the detected class
function CE:GetRotation()
    if not WCS.ClassRotations then return {} end
    local rot = WCS.ClassRotations:GetData()
    return rot and rot.rotation or {}
end

-- Returns the primary defensive/emergency spell
function CE:GetDefensive()
    if not WCS.ClassRotations then return nil end
    local rot = WCS.ClassRotations:GetData()
    return rot and rot.defensive or nil
end

-- Returns the buff/proc trigger that enables an instant/priority action
function CE:GetProcTrigger()
    if not WCS.ClassRotations then return nil end
    local rot = WCS.ClassRotations:GetData()
    return rot and rot.proc_trigger or nil
end

-- Returns the proc action (spell to cast when proc is active)
function CE:GetProcAction()
    if not WCS.ClassRotations then return nil end
    local rot = WCS.ClassRotations:GetData()
    return rot and rot.proc_action or self:GetFiller()
end

-- Returns whether this class natively has a combat pet
function CE:HasPet()
    return (self.class == "WARLOCK" or self.class == "HUNTER")
end

-- Returns whether this class uses mana
function CE:UsesMana()
    local noMana = { WARRIOR = true, ROGUE = true }
    return not noMana[self.class or ""]
end

-- Returns a human-readable color code for the class
function CE:GetClassColor()
    local colors = {
        WARLOCK  = "|cff8788ee",
        WARRIOR  = "|cffC69B3A",
        MAGE     = "|cff69CCF0",
        PRIEST   = "|cffFFFFFF",
        ROGUE    = "|cffFFF569",
        PALADIN  = "|cffF58CBA",
        DRUID    = "|cffFF7D0A",
        HUNTER   = "|cffABD473",
        SHAMAN   = "|cff0070DE",
    }
    return colors[self.class or ""] or "|cffFFFFFF"
end

-- ============================================================================
-- RACE BONUSES (Racial ability awareness)
-- ============================================================================
CE.RacialAbilities = {
    Undead   = { "Will of the Forsaken", "Touch of Weakness", "Cannibalize" },
    Orc      = { "Blood Fury", "Hardiness" },
    Troll    = { "Berserking", "Beast Slaying" },
    Tauren   = { "Warstomp", "Endurance" },
    Human    = { "Every Man for Himself", "Perception" },
    NightElf = { "Shadowmeld", "Quickness" },
    Gnome    = { "Escape Artist", "Expansive Mind" },
    Dwarf    = { "Stoneform", "Gun Specialization" },
}

function CE:GetRacials()
    return self.RacialAbilities[self.race] or {}
end

-- ============================================================================
-- INIT
-- ============================================================================
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    WCS.ClassEngine:Detect()
end)

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Brain]|r ClassEngine v1.0.0 cargado.")

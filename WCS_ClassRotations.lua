--[[
    WCS_ClassRotations.lua — Rotation Database v1.0.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Base de datos de rotaciones reales para las 9 clases de WoW 1.12.
    Las rotaciones son la prioridad de hechizos en orden de importancia.
    
    Funcionalidad REAL — Sin ficcion.
]]--

WCS = WCS or {}
WCS.ClassRotations = WCS.ClassRotations or {}
local CR = WCS.ClassRotations

CR.VERSION = "1.0.0"
CR._currentClass = "WARLOCK"

-- ============================================================================
-- ROTATION DATABASE
-- Each entry:
--   filler       = Primary spam spell (used when no priority applies)
--   rotation     = Priority list (highest first). Used by DecisionEngine.
--   defensive    = Emergency/survival spell
--   proc_trigger = Buff/aura name that signals a proc is active
--   proc_action  = Spell to cast when proc is up (usually free/instant)
--   resource     = Main resource ("mana", "energy", "rage", nil)
--   pet_class    = true if class uses a permanent pet
-- ============================================================================
CR.DB = {

    WARLOCK = {
        filler       = "Shadow Bolt",
        rotation     = {
            -- Priority order (highest first)
            "Curse of Agony",    -- keep up DoT
            "Corruption",        -- keep up DoT
            "Immolate",          -- keep up DoT
            "Shadow Bolt",       -- filler
        },
        defensive    = "Death Coil",
        proc_trigger = "Shadow Trance",  -- Nightfall proc
        proc_action  = "Shadow Bolt",    -- instant SB during Nightfall
        resource     = "mana",
        pet_class    = true,
    },

    MAGE = {
        filler       = "Frostbolt",
        rotation     = {
            "Fireball",          -- if fire spec
            "Scorch",            -- if fire, stack debuffs
            "Arcane Missiles",   -- if arcane spec + clearcast
            "Frostbolt",         -- frost filler / slow
        },
        defensive    = "Ice Block",
        proc_trigger = "Clearcasting",   -- Presence of Mind/Arcane Concentration
        proc_action  = "Pyroblast",      -- instant Pyroblast during PoM
        resource     = "mana",
        pet_class    = false,
    },

    PRIEST = {
        filler       = "Shadow Word: Pain",
        rotation     = {
            "Shadow Word: Pain",  -- DoT
            "Mind Flay",         -- channeled filler (shadow)
            "Vampiric Touch",    -- if shadow
            "Smite",             -- holy filler
        },
        defensive    = "Fade",
        proc_trigger = "Inner Focus",    -- free spell proc
        proc_action  = "Greater Heal",   -- free GH in emergencies
        resource     = "mana",
        pet_class    = false,
    },

    ROGUE = {
        filler       = "Sinister Strike",
        rotation     = {
            "Slice and Dice",    -- keep up buff (combo points)
            "Sinister Strike",   -- build combo points
            "Eviscerate",        -- spend combo points (5 cp)
        },
        defensive    = "Evasion",
        proc_trigger = "Slice and Dice",  -- not a proc but a buff to maintain
        proc_action  = "Sinister Strike",
        resource     = "energy",
        pet_class    = false,
    },

    WARRIOR = {
        filler       = "Heroic Strike",
        rotation     = {
            "Sunder Armor",      -- stack debuff
            "Overpower",         -- on dodge proc
            "Execute",           -- if target < 20% HP
            "Heroic Strike",     -- main filler (on next swing)
        },
        defensive    = "Shield Wall",
        proc_trigger = "Sword Specialization",  -- extra swing proc
        proc_action  = "Heroic Strike",
        resource      = "rage",
        pet_class    = false,
    },

    PALADIN = {
        filler       = "Seal of Command",
        rotation     = {
            "Blessing of Kings",   -- keep buff on self
            "Seal of Command",     -- keep seal up
            "Judgement",           -- judge every 8s
            "Holy Shock",          -- instant damage
        },
        defensive    = "Divine Shield",
        proc_trigger = "Vengeance",     -- Vengeance buff (Prot)
        proc_action  = "Holy Shield",
        resource     = "mana",
        pet_class    = false,
    },

    DRUID = {
        filler       = "Wrath",
        rotation     = {
            "Moonfire",          -- balance: keep DoT
            "Insect Swarm",      -- balance: keep DoT
            "Starfire",          -- balance: big hit
            "Wrath",             -- balance: filler
            -- Feral:
            "Mangle",            -- feral: keep up bleed
            "Shred",             -- feral: behind target
        },
        defensive    = "Barkskin",
        proc_trigger = "Clearcasting",   -- Omen of Clarity
        proc_action  = "Starsurge",      -- free cast during OoC
        resource     = "mana",
        pet_class    = false,
    },

    HUNTER = {
        filler       = "Arcane Shot",
        rotation     = {
            "Hunter's Mark",     -- keep debuff on target
            "Serpent Sting",     -- keep up DoT
            "Arcane Shot",       -- priority filler
            "Multi-Shot",        -- if multiple targets
        },
        defensive    = "Feign Death",
        proc_trigger = "Rapid Fire",    -- haste buff
        proc_action  = "Aimed Shot",    -- big shot during RF window
        resource     = "mana",
        pet_class    = true,
    },

    SHAMAN = {
        filler       = "Lightning Bolt",
        rotation     = {
            "Flame Shock",       -- keep up DoT
            "Chain Lightning",   -- if multiple targets
            "Lightning Bolt",    -- primary filler
            "Earth Shock",       -- interrupt / filler
        },
        defensive    = "Earth Shock",   -- kite tool
        proc_trigger = "Elemental Focus",    -- Clearcast after crit
        proc_action  = "Chain Lightning",    -- free CL during EF
        resource     = "mana",
        pet_class    = false,
    },
}

-- ============================================================================
-- INTERFACE
-- ============================================================================

function CR:SetClass(class)
    if self.DB[class] then
        self._currentClass = class
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffFF8800[WCS ClassRotations]|r Clase desconocida: " .. tostring(class) .. ". Usando WARLOCK como fallback.")
        self._currentClass = "WARLOCK"
    end
end

-- Returns the full rotation data for the current class
function CR:GetData()
    return self.DB[self._currentClass]
end

-- Returns only the rotation priority list
function CR:GetRotation()
    local d = self:GetData()
    return d and d.rotation or {}
end

-- Returns the filler spell name
function CR:GetFiller()
    local d = self:GetData()
    return d and d.filler or "Auto Attack"
end

-- Returns the defensive spell name
function CR:GetDefensive()
    local d = self:GetData()
    return d and d.defensive or nil
end

-- Returns the proc trigger buff name
function CR:GetProcTrigger()
    local d = self:GetData()
    return d and d.proc_trigger or nil
end

-- Returns the spell to cast on proc
function CR:GetProcAction()
    local d = self:GetData()
    return d and d.proc_action or self:GetFiller()
end

-- Returns all class names available in the DB
function CR:GetAllClasses()
    local classes = {}
    for cls, _ in pairs(self.DB) do
        table.insert(classes, cls)
    end
    return classes
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Brain]|r ClassRotations v1.0.0 — 9 clases cargadas.")

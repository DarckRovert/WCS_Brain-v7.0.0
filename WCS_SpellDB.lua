--[[
    WCS_SpellDB.lua - Base de Datos de Hechizos del Warlock
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Parte del sistema Cerebro Central Independiente
]]--

WCS_SpellDB = WCS_SpellDB or {}

-- ============================================================================
-- HECHIZOS DE DAÑO
-- ============================================================================
WCS_SpellDB.Damage = {
    -- Shadow Bolt (filler principal)
    ["Shadow Bolt"] = {
        id = 686,
        school = "shadow",
        type = "direct",
        castTime = 3.0,
        manaCost = 110,
        range = 30,
        ranks = {1, 3, 10, 18, 26, 34, 42, 50, 58}
    },
    
    -- Immolate (DoT + direct)
    ["Immolate"] = {
        id = 348,
        school = "fire",
        type = "dot",
        castTime = 2.0,
        duration = 15,
        manaCost = 85,
        range = 30,
        ranks = {1, 10, 20, 30, 40, 50, 60}
    },
    
    -- Corruption (instant DoT)
    ["Corruption"] = {
        id = 172,
        school = "shadow",
        type = "dot",
        castTime = 0, -- instant con talento
        duration = 18,
        manaCost = 100,
        range = 30,
        ranks = {4, 14, 24, 34, 44, 54}
    },
    
    -- Curse of Agony
    ["Curse of Agony"] = {
        id = 980,
        school = "shadow",
        type = "curse",
        castTime = 0,
        duration = 24,
        manaCost = 50,
        range = 30,
        ranks = {8, 18, 28, 38, 48, 58}
    },
    
    -- Curse of Doom
    ["Curse of Doom"] = {
        id = 603,
        school = "shadow",
        type = "curse",
        castTime = 0,
        duration = 60,
        cooldown = 60,
        manaCost = 300,
        range = 30,
        ranks = {60}
    },
    
    -- Siphon Life
    ["Siphon Life"] = {
        id = 18265,
        school = "shadow",
        type = "dot",
        castTime = 0,
        duration = 30,
        manaCost = 150,
        range = 30,
        ranks = {30, 38, 48, 58}
    },
    
    -- Drain Life
    ["Drain Life"] = {
        id = 689,
        school = "shadow",
        type = "channel",
        castTime = 5.0,
        manaCost = 55,
        range = 30,
        ranks = {14, 22, 30, 38, 46, 54}
    },
    
    -- Drain Soul
    ["Drain Soul"] = {
        id = 1120,
        school = "shadow",
        type = "channel",
        castTime = 15.0,
        manaCost = 55,
        range = 30,
        ranks = {10, 24, 38, 52}
    },
    
    -- Soul Fire
    ["Soul Fire"] = {
        id = 6353,
        school = "fire",
        type = "direct",
        castTime = 6.0,
        manaCost = 250,
        range = 30,
        ranks = {48, 56}
    },
    
    -- Searing Pain
    ["Searing Pain"] = {
        id = 5676,
        school = "fire",
        type = "direct",
        castTime = 1.5,
        manaCost = 45,
        range = 30,
        ranks = {18, 26, 34, 42, 50, 58}
    },
    
    -- Conflagrate
    ["Conflagrate"] = {
        id = 17962,
        school = "fire",
        type = "direct",
        castTime = 0,
        cooldown = 10,
        manaCost = 165,
        range = 30,
        requiresDebuff = "Immolate",
        ranks = {40, 48, 54, 60}
    },
    
    -- Shadowburn
    ["Shadowburn"] = {
        id = 17877,
        school = "shadow",
        type = "direct",
        castTime = 0,
        cooldown = 15,
        manaCost = 105,
        range = 30,
        ranks = {20, 28, 36, 44, 52, 60}
    },
    
    -- Rain of Fire (AoE)
    ["Rain of Fire"] = {
        id = 5740,
        school = "fire",
        type = "aoe_channel",
        castTime = 8.0,
        manaCost = 295,
        range = 30,
        ranks = {20, 34, 46, 58}
    },
    
    -- Hellfire (AoE)
    ["Hellfire"] = {
        id = 1949,
        school = "fire",
        type = "aoe_channel",
        castTime = 15.0,
        manaCost = 445,
        range = 0,
        ranks = {30, 42, 54}
    }
}

-- ============================================================================
-- HECHIZOS DE CONTROL
-- ============================================================================
WCS_SpellDB.Control = {
    ["Fear"] = {
        id = 5782,
        school = "shadow",
        type = "cc",
        castTime = 1.5,
        duration = 20,
        manaCost = 65,
        range = 20,
        ranks = {8, 32, 56}
    },
    
    ["Howl of Terror"] = {
        id = 5484,
        school = "shadow",
        type = "cc_aoe",
        castTime = 2.0,
        duration = 15,
        cooldown = 40,
        manaCost = 130,
        range = 10,
        ranks = {40, 52}
    },
    
    ["Death Coil"] = {
        id = 6789,
        school = "shadow",
        type = "cc",
        castTime = 0,
        duration = 3,
        cooldown = 120,
        manaCost = 430,
        range = 30,
        heals = true,
        ranks = {42, 50, 58}
    },
    
    ["Banish"] = {
        id = 710,
        school = "shadow",
        type = "cc",
        castTime = 1.5,
        duration = 30,
        manaCost = 75,
        range = 30,
        targetType = {"demon", "elemental"},
        ranks = {28, 48}
    },
    
    ["Curse of Tongues"] = {
        id = 1714,
        school = "shadow",
        type = "curse",
        castTime = 0,
        duration = 30,
        manaCost = 80,
        range = 30,
        ranks = {26, 50}
    },
    
    ["Curse of Exhaustion"] = {
        id = 18223,
        school = "shadow",
        type = "curse",
        castTime = 0,
        duration = 12,
        manaCost = 75,
        range = 30,
        ranks = {1} -- talento
    },
    
    ["Curse of Weakness"] = {
        id = 702,
        school = "shadow",
        type = "curse",
        castTime = 0,
        duration = 120,
        manaCost = 35,
        range = 30,
        ranks = {4, 14, 26, 36, 46, 56}
    },
    
    ["Curse of Recklessness"] = {
        id = 704,
        school = "shadow",
        type = "curse",
        castTime = 0,
        duration = 120,
        manaCost = 35,
        range = 30,
        ranks = {14, 28, 42, 56}
    },
    
    ["Curse of the Elements"] = {
        id = 1490,
        school = "shadow",
        type = "curse",
        castTime = 0,
        duration = 300,
        manaCost = 100,
        range = 30,
        ranks = {32, 44, 56}
    },
    
    ["Curse of Shadow"] = {
        id = 17862,
        school = "shadow",
        type = "curse",
        castTime = 0,
        duration = 300,
        manaCost = 100,
        range = 30,
        ranks = {44, 56}
    }
}

-- ============================================================================
-- HECHIZOS DEFENSIVOS / UTILIDAD
-- ============================================================================
WCS_SpellDB.Defensive = {
    ["Life Tap"] = {
        id = 1454,
        school = "shadow",
        type = "utility",
        castTime = 0,
        manaCost = 0,
        healthCost = true,
        range = 0,
        ranks = {6, 16, 26, 36, 46}
    },
    
    ["Dark Pact"] = {
        id = 18220,
        school = "shadow",
        type = "utility",
        castTime = 0,
        manaCost = 0,
        requiresPet = true,
        range = 0,
        ranks = {40, 50, 60}
    },
    
    ["Drain Mana"] = {
        id = 5138,
        school = "shadow",
        type = "channel",
        castTime = 5.0,
        manaCost = 0,
        range = 30,
        ranks = {24, 32, 40, 48}
    },
    
    ["Health Funnel"] = {
        id = 755,
        school = "shadow",
        type = "channel",
        castTime = 10.0,
        manaCost = 60,
        requiresPet = true,
        range = 45,
        ranks = {12, 20, 28, 36, 44, 52}
    },
    
    ["Unending Breath"] = {
        id = 5697,
        school = "shadow",
        type = "buff",
        castTime = 0,
        duration = 600,
        manaCost = 50,
        range = 30,
        ranks = {16}
    },
    
    ["Detect Invisibility"] = {
        id = 132,
        school = "shadow",
        type = "buff",
        castTime = 0,
        duration = 600,
        manaCost = 20,
        range = 30,
        ranks = {26, 38, 50}
    },
    
    ["Shadow Ward"] = {
        id = 6229,
        school = "shadow",
        type = "buff",
        castTime = 0,
        duration = 30,
        cooldown = 30,
        manaCost = 55,
        range = 0,
        ranks = {32, 42, 52}
    },
    
    ["Demon Armor"] = {
        id = 706,
        school = "shadow",
        type = "buff",
        castTime = 0,
        duration = 1800,
        manaCost = 120,
        range = 0,
        ranks = {20, 30, 40, 50, 60}
    },
    
    ["Demon Skin"] = {
        id = 687,
        school = "shadow",
        type = "buff",
        castTime = 0,
        duration = 1800,
        manaCost = 40,
        range = 0,
        ranks = {1, 10}
    },
    
    ["Soul Link"] = {
        id = 19028,
        school = "shadow",
        type = "buff",
        castTime = 0,
        manaCost = 0,
        requiresPet = true,
        range = 0,
        ranks = {1} -- talento
    },
    
    ["Fel Domination"] = {
        id = 18708,
        school = "shadow",
        type = "utility",
        castTime = 0,
        cooldown = 900,
        manaCost = 0,
        range = 0,
        ranks = {1} -- talento
    }
}

-- ============================================================================
-- INVOCACIONES DE MASCOTAS
-- ============================================================================
WCS_SpellDB.Summons = {
    ["Summon Imp"] = {
        id = 688,
        castTime = 10.0,
        manaCost = 100,
        shard = false,
        ranks = {1}
    },
    
    ["Summon Voidwalker"] = {
        id = 697,
        castTime = 10.0,
        manaCost = 100,
        shard = true,
        ranks = {10}
    },
    
    ["Summon Succubus"] = {
        id = 712,
        castTime = 10.0,
        manaCost = 100,
        shard = true,
        ranks = {20}
    },
    
    ["Summon Felhunter"] = {
        id = 691,
        castTime = 10.0,
        manaCost = 100,
        shard = true,
        ranks = {30}
    },
    
    ["Summon Felguard"] = {
        id = 30146,
        castTime = 10.0,
        manaCost = 100,
        shard = true,
        ranks = {50} -- talento demonología
    },
    
    ["Inferno"] = {
        id = 1122,
        castTime = 2.0,
        cooldown = 3600,
        manaCost = 0,
        reagent = "Infernal Stone",
        ranks = {50}
    },
    
    ["Ritual of Doom"] = {
        id = 18540,
        castTime = 0,
        cooldown = 3600,
        manaCost = 0,
        reagent = "Demonic Figurine",
        ranks = {60}
    }
}

-- ============================================================================
-- HABILIDADES DE MASCOTAS
-- ============================================================================
WCS_SpellDB.PetAbilities = {
    -- Imp
    ["Firebolt"] = {pet = "imp", type = "damage", castTime = 2.0},
    ["Fire Shield"] = {pet = "imp", type = "buff"},
    ["Blood Pact"] = {pet = "imp", type = "buff"},
    ["Phase Shift"] = {pet = "imp", type = "defensive"},
    
    -- Voidwalker
    ["Torment"] = {pet = "voidwalker", type = "taunt"},
    ["Consume Shadows"] = {pet = "voidwalker", type = "heal"},
    ["Sacrifice"] = {pet = "voidwalker", type = "defensive"},
    ["Suffering"] = {pet = "voidwalker", type = "taunt_aoe"},
    
    -- Succubus
    ["Lash of Pain"] = {pet = "succubus", type = "damage"},
    ["Seduction"] = {pet = "succubus", type = "cc"},
    ["Soothing Kiss"] = {pet = "succubus", type = "debuff"},
    ["Lesser Invisibility"] = {pet = "succubus", type = "defensive"},
    
    -- Felhunter
    ["Shadow Bite"] = {pet = "felhunter", type = "damage"},
    ["Spell Lock"] = {pet = "felhunter", type = "interrupt", cooldown = 24},
    ["Devour Magic"] = {pet = "felhunter", type = "dispel"},
    ["Paranoia"] = {pet = "felhunter", type = "buff"},
    
    -- Felguard
    ["Cleave"] = {pet = "felguard", type = "damage"},
    ["Intercept"] = {pet = "felguard", type = "charge"},
    ["Anguish"] = {pet = "felguard", type = "taunt"},
    ["Demonic Frenzy"] = {pet = "felguard", type = "buff"}
}

-- ============================================================================
-- TEXTURAS DE DEBUFFS (para detección)
-- ============================================================================
WCS_SpellDB.DebuffTextures = {
    -- DoTs
    ["Interface\\Icons\\Spell_Shadow_AbominationExplosion"] = "Corruption",
    ["Interface\\Icons\\Spell_Fire_Immolation"] = "Immolate",
    ["Interface\\Icons\\Spell_Shadow_CurseOfSargeras"] = "Curse of Agony",
    ["Interface\\Icons\\Spell_Shadow_CurseOfAchimonde"] = "Curse of Doom",
    ["Interface\\Icons\\Spell_Shadow_Requiem"] = "Siphon Life",
    
    -- Curses
    ["Interface\\Icons\\Spell_Shadow_CurseOfTounable"] = "Curse of Tongues",
    ["Interface\\Icons\\Spell_Shadow_GrimWard"] = "Curse of Weakness",
    ["Interface\\Icons\\Spell_Shadow_UnholyStrength"] = "Curse of Recklessness",
    ["Interface\\Icons\\Spell_Shadow_ChillTouch"] = "Curse of the Elements",
    ["Interface\\Icons\\Spell_Shadow_CurseOfAchimonde"] = "Curse of Shadow",
    
    -- CC
    ["Interface\\Icons\\Spell_Shadow_Possession"] = "Fear",
    ["Interface\\Icons\\Spell_Shadow_DeathScream"] = "Howl of Terror"
}

-- ============================================================================
-- FUNCIONES DE UTILIDAD
-- ============================================================================

-- Obtener info de hechizo por nombre
function WCS_SpellDB:GetSpell(name)
    if self.Damage[name] then return self.Damage[name] end
    if self.Control[name] then return self.Control[name] end
    if self.Defensive[name] then return self.Defensive[name] end
    if self.Summons[name] then return self.Summons[name] end
    return nil
end

-- Verificar si es un DoT
function WCS_SpellDB:IsDot(name)
    local spell = self.Damage[name]
    if spell and spell.type == "dot" then return true end
    return false
end

-- Verificar si es una Curse
function WCS_SpellDB:IsCurse(name)
    local spell = self.Damage[name] or self.Control[name]
    if spell and spell.type == "curse" then return true end
    return false
end

-- Obtener duración de DoT/Curse
function WCS_SpellDB:GetDuration(name)
    local spell = self:GetSpell(name)
    if spell and spell.duration then
        return spell.duration
    end
    return 0
end

-- Obtener nombre de debuff por textura
function WCS_SpellDB:GetDebuffByTexture(texture)
    return self.DebuffTextures[texture]
end

-- Verificar si el jugador conoce el hechizo
function WCS_SpellDB:PlayerKnowsSpell(name)
    -- Buscar en el spellbook
    local i = 1
    while true do
        local spellName = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then break end
        if spellName == name then return true end
        i = i + 1
    end
    return false
end

-- Obtener rango máximo conocido
function WCS_SpellDB:GetMaxRank(name)
    local maxRank = 0
    local i = 1
    while true do
        local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then break end
        if spellName == name then
            local rank = 1
            if spellRank then
                local _, _, num = string.find(spellRank, "(%d+)")
                if num then rank = tonumber(num) or 1 end
            end
            if rank > maxRank then maxRank = rank end
        end
        i = i + 1
    end
    return maxRank
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS_SpellDB]|r Base de datos de hechizos cargada.")


--[[
    WCS_BrainSim.lua - Simulador de Daño Predictivo en Tiempo Real
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Este módulo calcula el valor real (DPS/DPCT) de los hechizos basándose
    en sus tooltips y el estado actual del objetivo.
]]--

WCS_BrainSim = WCS_BrainSim or {}
WCS_BrainSim.VERSION = "1.0.0"

-- Tooltip Scanner para leer datos de hechizos
local tooltipScanner = CreateFrame("GameTooltip", "WCS_SimTooltip", nil, "GameTooltipTemplate")
tooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

-- ============================================================================
-- BASE DE DATOS DE HECHIZOS (Coeficientes y Tiempos Base)
-- ============================================================================
-- Datos de referencia para Warlock 1.12
WCS_BrainSim.SpellData = {
    ["Shadow Bolt"] = { school = "Shadow", castTime = 3.0, coeff = 0.857 },
    ["Searing Pain"] = { school = "Fire", castTime = 1.5, coeff = 0.429 },
    ["Soul Fire"] = { school = "Fire", castTime = 6.0, coeff = 1.0 }, -- 4s con talento? Checkear despues
    ["Immolate"] = { school = "Fire", castTime = 2.0, coeff = 0.2, isDoT = true }, -- Parte inicial
    ["Corruption"] = { school = "Shadow", castTime = 2.0, coeff = 0.0, isDoT = true }, -- Instant con talento
    ["Curse of Agony"] = { school = "Shadow", castTime = 0, coeff = 0.0, isDoT = true },
    ["Siphon Life"] = { school = "Shadow", castTime = 0, coeff = 0.0, isDoT = true },
    ["Drain Life"] = { school = "Shadow", castTime = 5.0, coeff = 0.5, isChanneled = true },
    ["Death Coil"] = { school = "Shadow", castTime = 0, coeff = 0.429 },
    ["Shadowburn"] = { school = "Shadow", castTime = 0, coeff = 0.429 }
}

-- ============================================================================
-- PARSER DE TOOLTIPS
-- ============================================================================

-- Extraer daño min/max del texto del tooltip
local function ParseDamageFromTooltip(text)
    if not text then return 0, 0 end
    
    -- Patrones comunes:
    -- "Causes 100 to 120 Shadow damage"
    -- "Immolates the target for 100 Fire damage"
    
    local minDmg, maxDmg = 0, 0
    
    -- Intentar encontrar rango "100 to 120"
    local s, e, d1, d2 = string.find(text, "(%d+) to (%d+)")
    if d1 and d2 then
        minDmg = tonumber(d1)
        maxDmg = tonumber(d2)
    else
        -- Intentar encontrar daño único "for 100"
        s, e, d1 = string.find(text, "for (%d+)")
        if d1 then
            minDmg = tonumber(d1)
            maxDmg = minDmg
        end
    end
    
    return minDmg, maxDmg
end

-- ============================================================================
-- MOTOR DE CÁLCULO
-- ============================================================================

function WCS_BrainSim:GetSpellDamage(spellName, slot)
    tooltipScanner:ClearLines()
    if slot then
        tooltipScanner:SetSpell(slot, BOOKTYPE_SPELL)
    else
        -- Fallback lento si no tenemos slot (no recomendado en combate)
        -- Necesitamos encontrar el slot primero
        return 0
    end
    
    -- Leer línea de descripción (usualmente linea 2 o 3, dependiendo de si tiene coste de maná)
    local descText = WCS_SimTooltipTextLeft2:GetText()
    local min, max = ParseDamageFromTooltip(descText)
    
    if min == 0 then
        -- Probar linea 3 por si acaso
        descText = WCS_SimTooltipTextLeft3:GetText()
        min, max = ParseDamageFromTooltip(descText)
    end
    
    return (min + max) / 2 -- Daño promedio base (incluye SP del gear)
end

-- Calcular modificadores por Buffs/Debuffs
function WCS_BrainSim:GetModifiers(school)
    local mod = 1.0
    
    -- 1. Debuffs en Objetivo
    if UnitExists("target") then
        -- Shadow Weaving (hasta 15% shadow)
        if school == "Shadow" then
            local count = 0
            -- Necesitaríamos escanear stacks, asumiremos 0 si no tenemos lib, o implementar escaneo
            -- Por simplicidad v1: Detectar solo si existe, asumir 1 stack (3%)
            -- TODO: Implementar conteo de stacks real
        end
        
        -- Curse of Elements / Shadow
        if school == "Shadow" or school == "Arcane" then
            if WCS_BrainCore:TargetHasDebuff("Curse of Shadow") then mod = mod * 1.10 end
        elseif school == "Fire" or school == "Frost" then
            if WCS_BrainCore:TargetHasDebuff("Curse of the Elements") then mod = mod * 1.10 end
        end
    end
    
    -- 2. Buffs propios (Power Infusion, etc)
    -- Power Infusion (20% daño)
    if WCS_BrainCore:HasBuff("Power Infusion") then mod = mod * 1.20 end
    
    -- Demonic Sacrifice (Succubus = 15% Shadow, Imp = 15% Fire)
    if WCS_BrainCore:HasBuff("Touch of Shadow") then -- Sacrificio Succubus
        if school == "Shadow" then mod = mod * 1.15 end
    end
    if WCS_BrainCore:HasBuff("Burning Wish") then -- Sacrificio Imp
        if school == "Fire" then mod = mod * 1.15 end
    end
    
    return mod
end

-- Calcular DPCT (Damage Per Cast Time)
-- Retorna: Valor estimado, Tiempo de cast efectivo
function WCS_BrainSim:EvaluateSpell(spellName)
    local data = self.SpellData[spellName]
    if not data then return 0, 0 end
    
    local slot = WCS_BrainCore:FindSpellSlot(spellName)
    if not slot then return 0, 0 end
    
    -- 1. Obtener daño base del tooltip (incluye Gear SP)
    local baseDmg = self:GetSpellDamage(spellName, slot)
    if baseDmg == 0 then return 0, 0 end -- Error leyendo o hechizo de utilidad
    
    -- 2. Modificadores
    local modifiers = self:GetModifiers(data.school)
    
    -- 3. Tiempo de Casteo (leer del tooltip para incluir talentos como Bane)
    -- Esto es mas preciso que data.castTime fijo
    local start, duration = GetSpellCooldown(slot, BOOKTYPE_SPELL) -- Esto da CD, no cast time
    -- GetSpellInfo no existe en 1.12 para cast time directo, hay que parsear
    -- Por ahora usaremos la tabla estática ajustada
    local castTime = data.castTime
    
    -- Ajuste por talentos (hardcoded por ahora, idealmente leer talent tree)
    -- Bane: -0.5s a Shadow Bolt / Immolate
    -- Asumimos que si el usuario tiene Brain, tiene talentos decentes (?)
    -- Mejor: Si data.castTime > 1.5, usar floor de 1.5 por seguridad del GCD
    
    if castTime < 1.5 and castTime > 0 then castTime = 1.5 end -- GCD Floor
    if castTime == 0 then castTime = 1.5 end -- Instants usan GCD
    
    -- 4. Cálculo final
    local finalDmg = baseDmg * modifiers
    local dpct = finalDmg / castTime
    
    -- Bonus crítico (simplificado: media 10% chance * 1.5 dmg = 5% extra avg)
    -- TODO: Leer crit real del libro de hechizos
    dpct = dpct * 1.05 
    
    return dpct, castTime
end

-- ============================================================================
-- API PÚBLICA DE DECISIÓN
-- ============================================================================

-- Compara dos hechizos y retorna el mejor basado en DPCT
function WCS_BrainSim:CompareSpells(spellA, spellB)
    local valA, timeA = self:EvaluateSpell(spellA)
    local valB, timeB = self:EvaluateSpell(spellB)
    
    if valA > valB then
        return spellA, valA
    else
        return spellB, valB
    end
end

-- Retorna el valor numérico de un hechizo para el sistema de Scoring
function WCS_BrainSim:GetScore(spellName)
    local dpct, _ = self:EvaluateSpell(spellName)
    return dpct
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS_BrainSim]|r Motor Predictivo cargado")

--[[
    WCS_SpellDB_Patch.lua - Parche de Localización COMPLETO para WCS_Brain
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    ESTRATEGIA: Sobrescribir GetSpellName() de la API de WoW para que SIEMPRE
    devuelva nombres en inglés, haciendo que TODO el addon funcione transparentemente.
    
    Autor: Elnazzareno (DarckRovert)
]]--

-- ============================================================================
-- CACHE DE NOMBRES NORMALIZADOS
-- ============================================================================
local SpellNameCache = {}
local OriginalGetSpellName = GetSpellName

-- Sobrescribir GetSpellName GLOBALMENTE
function GetSpellName(spellId, bookType)
    local name, rank = OriginalGetSpellName(spellId, bookType)
    
    if name and WCS_SpellLocalization then
        -- Crear clave de cache
        local cacheKey = name .. (rank or "")
        
        if not SpellNameCache[cacheKey] then
            -- Normalizar y cachear
            local normalized = WCS_SpellLocalization:NormalizeSpellName(name)
            SpellNameCache[cacheKey] = normalized
            
            -- Debug: mostrar normalización solo si cambió
            if normalized ~= name then
                DEFAULT_CHAT_FRAME:AddMessage("[WCS_Localization] '" .. name .. "' -> '" .. normalized .. "'")
            end
        end
        
        return SpellNameCache[cacheKey], rank
    end
    
    return name, rank
end

-- ============================================================================
-- PARCHE PARA WCS_BrainCore - FindSpellSlot
-- ============================================================================
local function PatchBrainCore()
    if not WCS_BrainCore then
        return
    end
    
    -- Reemplazar completamente FindSpellSlot (no guardar original para evitar recursión)
    function WCS_BrainCore:FindSpellSlot(spellName)
        -- Normalizar el nombre del hechizo buscado
        local normalizedSearchName = spellName
        if WCS_SpellLocalization then
            normalizedSearchName = WCS_SpellLocalization:NormalizeSpellName(spellName)
            if normalizedSearchName ~= spellName then
                DEFAULT_CHAT_FRAME:AddMessage("[FindSpellSlot] Normalizado: " .. spellName .. " -> " .. normalizedSearchName)
            end
        end
        
        local i = 1
        local bestSlot = nil
        local bestRank = 0
        
        while true do
            local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
            if not name then break end
            
            -- Normalizar el nombre del hechizo del spellbook
            local normalizedSpellbookName = name
            if WCS_SpellLocalization then
                normalizedSpellbookName = WCS_SpellLocalization:NormalizeSpellName(name)
            end
            
            -- Comparar nombres normalizados
            if normalizedSpellbookName == normalizedSearchName then
                local rankNum = 1
                if rank then
                    local _, _, num = string.find(rank, "(%d+)")
                    if num then rankNum = tonumber(num) or 1 end
                end
                if rankNum > bestRank then
                    bestRank = rankNum
                    bestSlot = i
                end
            end
            i = i + 1
        end
        
        return bestSlot, bestRank
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS_BrainCore_Patch]|r Parche de localización aplicado a FindSpellSlot")
end

-- ============================================================================
-- PARCHE PARA WCS_BrainPetAI - ScanPetAbilities
-- ============================================================================
local function PatchPetAI()
    if not WCS_BrainPetAI then
        return
    end
    
    -- Reemplazar completamente ScanPetAbilities
    function WCS_BrainPetAI:ScanPetAbilities()
        local abilities = {}
        if not UnitExists("pet") then return abilities end
        
        for i = 1, 10 do
            local name, subtext, texture = GetPetActionInfo(i)
            if name and name ~= "" then
                -- Normalizar el nombre de la habilidad
                local normalizedName = name
                if WCS_SpellLocalization then
                    normalizedName = WCS_SpellLocalization:NormalizeSpellName(name)
                end
                
                local cat = self:ClassifyAbility(normalizedName, texture)
                local ab = {}
                ab.slot = i
                ab.name = tostring(normalizedName)  -- Usar nombre normalizado
                ab.originalName = tostring(name)     -- Guardar nombre original
                ab.texture = tostring(texture or "")
                ab.category = cat
                table.insert(abilities, ab)
            end
        end
        return abilities
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS_PetAI_Patch]|r Parche de localización aplicado a ScanPetAbilities")
end

-- ============================================================================
-- PARCHE PARA WCS_SpellDB - Funciones de búsqueda
-- ============================================================================
local function PatchSpellDB()
    if not WCS_SpellDB then
        return
    end
    
    -- Reemplazar PlayerKnowsSpell completamente
    function WCS_SpellDB:PlayerKnowsSpell(name)
        local normalizedName = name
        if WCS_SpellLocalization then
            normalizedName = WCS_SpellLocalization:NormalizeSpellName(name)
        end
        
        local i = 1
        while true do
            local spellName = GetSpellName(i, BOOKTYPE_SPELL)
            if not spellName then break end
            
            local normalizedSpellName = spellName
            if WCS_SpellLocalization then
                normalizedSpellName = WCS_SpellLocalization:NormalizeSpellName(spellName)
            end
            
            if normalizedSpellName == normalizedName then
                return true
            end
            i = i + 1
        end
        return false
    end
    
    -- Reemplazar GetMaxRank completamente
    function WCS_SpellDB:GetMaxRank(name)
        local normalizedName = name
        if WCS_SpellLocalization then
            normalizedName = WCS_SpellLocalization:NormalizeSpellName(name)
        end
        
        local maxRank = 0
        local i = 1
        while true do
            local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
            if not spellName then break end
            
            local normalizedSpellName = spellName
            if WCS_SpellLocalization then
                normalizedSpellName = WCS_SpellLocalization:NormalizeSpellName(spellName)
            end
            
            if normalizedSpellName == normalizedName then
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
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS_SpellDB_Patch]|r Parche de localización aplicado a PlayerKnowsSpell y GetMaxRank")
end

-- ============================================================================
-- COMANDO DE DEBUG: /listspells
-- ============================================================================
SlashCmdList["LISTSPELLS"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9========== LISTA DE HECHIZOS ==========|r")
    local i = 1
    while true do
        local spellName, spellRank = OriginalGetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then break end
        
        local normalized = WCS_SpellLocalization:NormalizeSpellName(spellName)
        if normalized ~= spellName then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00" .. spellName .. "|r -> |cFF00FF00" .. normalized .. "|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. spellName .. "|r (SIN TRADUCCIÓN)")
        end
        i = i + 1
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9====================================|r")
end
SLASH_LISTSPELLS1 = "/listspells"

-- Aplicar los parches cuando el addon se cargue
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "WCS_Brain" then
        DEFAULT_CHAT_FRAME:AddMessage("[WCS_SpellDB_Patch] Sistema de localización GLOBAL activado")
        DEFAULT_CHAT_FRAME:AddMessage("[WCS_SpellDB_Patch] GetSpellName() sobrescrito - todos los hechizos se normalizarán automáticamente")
        DEFAULT_CHAT_FRAME:AddMessage("[WCS_SpellDB_Patch] Usa /listspells para ver todos tus hechizos y sus traducciones")
        PatchSpellDB()
        PatchBrainCore()
        PatchPetAI()
        DEFAULT_CHAT_FRAME:AddMessage("[WCS_SpellDB_Patch] Soporte multiidioma completo activado!")
    end
end)

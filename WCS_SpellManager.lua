--[[
    WCS_SpellManager.lua - Tactical Spell Execution v8.0.0 (Unified)
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}
WCS.SpellManager = WCS.SpellManager or {}
local SM = WCS.SpellManager

function SM:Cast(spellName)
    if WCS.Core and WCS.Core.IsCasting then return false end
    if WCS.Core and WCS.Core:IsMounted() then WCS.Core:Dismount() return false end

    local slot = self:GetSlot(spellName)
    if slot then
        CastSpell(slot, BOOKTYPE_SPELL)
        WCS:Log("Lanzando: " .. spellName)
        return true
    end
    return false
end

function SM:GetSlot(name)
    local i = 1
    local best = nil
    while true do
        local n = GetSpellName(i, BOOKTYPE_SPELL)
        if not n then break end
        if n == name then best = i end
        i = i + 1
    end
    return best
end

-- [Legacy & Sim Compatibility Bridge]
function SM:FindSpellSlot(name) return self:GetSlot(name) end

function SM:GetIcon(name)
    local i = 1
    while true do
        local n = GetSpellName(i, BOOKTYPE_SPELL)
        if not n then break end
        if n == name then return GetSpellTexture(i, BOOKTYPE_SPELL) end
        i = i + 1
    end
    return nil
end

WCS:Log("Spell Manager v8.0.0 (Unified Interface) Ready.")

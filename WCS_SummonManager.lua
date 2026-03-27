--[[
    WCS_SummonManager.lua - Tactical Summoning v9.3.0 (Unified)
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}
WCS.SummonManager = WCS.SummonManager or {}
local SM = WCS.SummonManager

SM.Queue = {}

function SM:OnChat(msg, sender)
    local m = string.lower(msg or "")
    if string.find(m, "123") or string.find(m, "summon") or string.find(m, "inv") then
        WCS:Log("PeticiÃ³n de Summon: " .. sender)
        
        -- Evitar duplicados
        local found = false
        for _, name in pairs(self.Queue) do if name == sender then found = true break end end
        if not found then table.insert(self.Queue, sender) end
        
        WCS:Notify("PeticiÃ³n de Summon: " .. sender)
        if WCS.UI then WCS.UI:RefreshCurrentTab() end
    end
end

function SM:ExecuteSummon(name)
    TargetByName(name, true)
    if UnitName("target") == name then
        WCS:Log("Invocando a " .. name .. "...")
        CastSpellByName("Ritual of Summoning")
        self:RemoveFromQueue(name)
    else
        WCS:Error("No se pudo fijar como objetivo a: " .. name)
    end
end

function SM:RemoveFromQueue(name)
    for i, n in pairs(self.Queue) do
        if n == name then table.remove(self.Queue, i) break end
    end
    if WCS.UI then WCS.UI:RefreshCurrentTab() end
end

-- [Event Hooks via Central EM]
if WCS.EventManager then
    local function Handle(m, s) SM:OnChat(m, s) end
    WCS.EventManager:Register("CHAT_MSG_WHISPER", Handle)
    WCS.EventManager:Register("CHAT_MSG_RAID", Handle)
    WCS.EventManager:Register("CHAT_MSG_PARTY", Handle)
    WCS.EventManager:Register("CHAT_MSG_GUILD", Handle)
end

WCS:Log("Summon Manager v9.3.0 (Data-Bound) Ready.")

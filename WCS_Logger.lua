--[[
    WCS_Logger.lua - Forensic Audit v9.3.0 (Hardened)
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}
WCS.Logger = WCS.Logger or {}
local L = WCS.Logger

L.Entries = {}
L.MaxEntries = 80

function L:Log(level, module, msg)
    local entry = { time = date("%H:%M:%S"), level = level or "INFO", module = module or "WCS", text = msg }
    table.insert(self.Entries, 1, entry)
    if table.getn(self.Entries) > self.MaxEntries then table.remove(self.Entries) end
    
    -- v9.3.0 Fix: Defer sync to SavedVars until after it's validated
    if WCS.DataIsReady and WCS_BrainSaved then 
        WCS_BrainSaved.Log = self.Entries 
    end
end

-- Overwrite the stub from WCS_Base
function WCS:Log(msg) 
    L:Log("INFO", "Master", msg) 
    DEFAULT_CHAT_FRAME:AddMessage("|cff9482C9[WCS]|r " .. (msg or "")) 
end

WCS:Log("Forensic Logger v9.3.0 Aligned.")

--[[
    WCS_Base.lua - Absolute Foundation v9.3.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}

function WCS:Log(msg) 
    DEFAULT_CHAT_FRAME:AddMessage("|cff9482C9[WCS LOAD]|r " .. (msg or "")) 
end

function WCS:Error(msg) 
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[WCS ERROR]|r " .. (msg or "")) 
end

function WCS:Notify(msg, color)
    -- Honor Config Toggle
    if WCS_BrainSaved and WCS_BrainSaved.Config and not WCS_BrainSaved.Config.Notifications then return end
    
    if WCS.NotificationManager then
        WCS.NotificationManager:Notify(msg, color or {r=1, g=1, b=1})
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00[WCS]|r " .. (msg or ""))
    end
end

function WCS:GetMemory()
    return math.floor(gcinfo()) .. " KB"
end

WCS:Log("Foundation Aligned (Notification Filter Ready).")

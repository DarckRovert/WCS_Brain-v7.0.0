--[[
    WCS_NotificationManager.lua - Tactical Alert System v9.3.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Alertas visuales en el centro de la pantalla para eventos crÃ­ticos.
]]--

WCS = WCS or {}
WCS.NotificationManager = WCS.NotificationManager or {}
local NM = WCS.NotificationManager

function NM:Notify(msg, color)
    UIErrorsFrame:AddMessage(msg, color.r, color.g, color.b, 1.0, UIERRORS_HOLD_TIME)
    WCS:Log("|cff" .. string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255) .. "[ALERTA] " .. msg .. "|r")
end

function NM:Flash(msg)
    RaidNotice_AddMessage(RaidWarningFrame, "|cffff0000" .. msg .. "|r", { r=1, g=0, b=0 })
end
